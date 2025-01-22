targetScope = 'subscription'

param resourceGroupName string
param resourceGroupLocation string

resource rsrcGrpPdm 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: resourceGroupLocation
}

output id string = rsrcGrpPdm.id
