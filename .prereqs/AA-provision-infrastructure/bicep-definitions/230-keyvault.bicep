targetScope = 'resourceGroup'

// var envToppings = {
//   dev: 'dill'
//   stg: 'sausage'
//   prd: 'pepperoni'
// }

param keyVaultName string
param keyVaultEnvNickname string
param keyVaultLocation string
param consumingSynapseWorkspacePrincipalId string
param consumingSynapseWorkspaceName string

//var envTopping = envToppings[?keyVaultEnvNickname]
var secretValue = empty(keyVaultEnvNickname) ? 'mystery' : keyVaultEnvNickname

resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: keyVaultName
  location: keyVaultLocation
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
  }
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: kv
  name: 'flavor'
  properties: {
    value: secretValue
  }
}

resource kvsuRole 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: kv
  name: '4633458b-17de-408a-b874-0445c86b69e6' // GUID for 'Key Vault Secrets User'
}

resource rasecretsuser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: kv
  name: guid(kv.id, consumingSynapseWorkspacePrincipalId, kvsuRole.id)
  properties: {
    description: 'Allows ${consumingSynapseWorkspaceName} to read secrets from ${kv.name}.'
    principalId: consumingSynapseWorkspacePrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: kvsuRole.id
  }
}
