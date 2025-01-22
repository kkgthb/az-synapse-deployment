targetScope = 'resourceGroup'

param swName string
param swLocation string
param saName string
param repoName string
param repoOwner string
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
    workspaceRepositoryConfiguration: {
      type: 'FactoryGitHubConfiguration'
      repositoryName: repoName
      accountName: repoOwner
      collaborationBranch: 'main'
      rootFolder: '/src/mysynapse'
    }
  }
}

// resource sbdcRole 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
//   scope: stgAcctForSyn
//   name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // GUID for 'Storage Blob Data Contributor'
// }

// resource rasbdc 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   scope: stgAcctForSyn
//   name: guid(stgAcctForSyn.id, synWksp.id, sbdcRole.id) // I don't like it, but I'm gonna do it.  Wanted synWksp.identity.principalId in the middle, I thought.
//   properties: {
//     description: 'Allows ${synWksp.name} to read write to ${stgAcctForSyn.name}.'
//     principalId: synWksp.identity.principalId
//     principalType: 'ServicePrincipal'
//     roleDefinitionId: synWksp.identity.principalId
//   }
// }
