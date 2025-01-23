targetScope = 'subscription'

var solutionName = 'neurons'
var location = 'centralus'

param envNickname string
param thisRepoName string
param thisRepoOwner string

module rsrcGrp './100-resourcegroup.bicep' = {
  name: '${solutionName}-rg-${envNickname}'
  scope: subscription()
  params: {
    resourceGroupName: '${solutionName}-rg-${envNickname}'
    resourceGroupLocation: location
  }
}

module sw './200-synapseworkspace.bicep' = {
  name: '${solutionName}-sw-${envNickname}'
  scope: resourceGroup(rsrcGrp.name)
  params: {
    swName: '${solutionName}-sw-${envNickname}'
    swLocation: location
    saName: '${solutionName}sa${envNickname}'
    repoName: thisRepoName
    repoOwner: thisRepoOwner
  }
}

module kv './230-keyvault.bicep' = {
  name: '${solutionName}-kv-${envNickname}'
  scope: resourceGroup(rsrcGrp.name)
  params: {
    keyVaultName: '${solutionName}-kv-${envNickname}'
    keyVaultEnvNickname: envNickname
    keyVaultLocation: location
    consumingSynapseWorkspacePrincipalId: sw.outputs.principalId
    consumingSynapseWorkspaceName: sw.name
  }
}
