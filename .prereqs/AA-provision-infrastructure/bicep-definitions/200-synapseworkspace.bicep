targetScope = 'resourceGroup'

param swName string
param swLocation string
param saName string
param ghRepoName string
param ghOwner string
param entraTenantId string
param adoAcct string
param adoProj string
var defaultDataLakeStorageFilesystemName = 'synapseblob' // "The name of the default ADLS Gen2 file system for the data lake storage account. Required and can be any string."  https://github.com/AzDocs/AzDocs/blob/08ccb21/src-bicep/Synapse/workspaces.bicep#L69
@description('The format for the data lake URL in the Synapse workspace.')
var datalakeUrlFormat = 'https://{0}.dfs.${environment().suffixes.storage}'


resource stgAcctForSyn 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: saName
  location: swLocation
  kind: 'StorageV2'
  sku: {
    // https://learn.microsoft.com/en-us/rest/api/storagerp/srp_sku_types
    // https://www.cloudbolt.io/azure-costs/azure-storage-pricing/
    name: 'Standard_LRS' // This seems to be the cheapest available
  }
}

resource synWksp 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: swName
  location: swLocation
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    azureADOnlyAuthentication: true
    defaultDataLakeStorage: {
      resourceId: stgAcctForSyn.id
      accountUrl: format(datalakeUrlFormat, stgAcctForSyn.name) // https://github.com/AzDocs/AzDocs/blob/08ccb21/src-bicep/Synapse/workspaces.bicep#L118
      filesystem: defaultDataLakeStorageFilesystemName
    }
    // workspaceRepositoryConfiguration: {
    //   type: 'WorkspaceGitHubConfiguration'
    //   repositoryName: ghRepoName
    //   accountName: ghOwner
    //   collaborationBranch: 'main'
    //   rootFolder: '/src/mysynapse'
    // }
    // workspaceRepositoryConfiguration: {
    //   type: 'WorkspaceVSTSConfiguration'
    //   repositoryName: ghRepoName
    //   projectName: adoProj
    //   accountName: adoAcct
    //   tenantId: entraTenantId
    //   collaborationBranch: 'main' // I can't seem to get any Bicep-based repo syncing set up because there is no way to set a publishBranch, and then Synapse Studio complains.
    //   rootFolder: '/src/mysynapse' // Under what folder should Synapse Studio add a folder named "integrationRuntime", a folder named "pipeline", etc.?
    // }
  }
}

output principalId string = synWksp.identity.principalId

// Create role assignment
module sbdcRoleAssignment '201-sdbcroleassignment.bicep' = {
  name: 'sbdc-role-assignment'
  scope: resourceGroup()
  params:{
    storageAccountName: stgAcctForSyn.name
    principalId: synWksp.identity.principalId
    principalName: synWksp.name
  }
}
