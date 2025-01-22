targetScope = 'resourceGroup'

// storage-account-role-assignment.bicep
param storageAccountName string
param principalId string
param principalName string

// Get a reference to the storage account
resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource sbdcRole 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: sa
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // GUID for 'Storage Blob Data Contributor'
}

resource rasbdc 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: sa
  name: guid(sa.id, principalId, sbdcRole.id)
  properties: {
    description: 'Allows ${principalName} to read write to ${sa.name}.'
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: sbdcRole.id
  }
}
