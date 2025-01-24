$EnvNickname = 'prd'
$SolutionName = 'neurons'
$TenantId = az account show --query 'tenantId' --output 'tsv'
$ServicePrincipalDisplayName = Read-Host -Prompt 'Display name of the Entra service principal you would like to create a connection to'
$ServicePrincipalId = az ad sp list --display-name $ServicePrincipalDisplayName --query '[].appId' --output 'tsv'
$SubscriptionName = 'Visual Studio Professional Subscription'
$SubscriptionId = az account show --subscription $SubscriptionName --query 'id' --output 'tsv'
$ResourceGroupName = "$SolutionName-rg-$EnvNickname"
$CurrentGitRemoteUrl = [System.Uri](git remote get-url origin)
$AdoOrg = $CurrentGitRemoteUrl.Scheme + '://' + $CurrentGitRemoteUrl.Host + $CurrentGitRemoteUrl.Segments[0] + $CurrentGitRemoteUrl.Segments[1]
$AdoOrgName = $CurrentGitRemoteUrl.Segments[1].TrimEnd('/')
$AdoProject = $CurrentGitRemoteUrl.Segments[2].TrimEnd('/')
$AdoProjectId = az devops project show --organization $AdoOrg --project $AdoProject --query 'id' --output 'tsv'
$AdoDesiredServiceConnectionName = "SC-federatedidentity--$ServicePrincipalDisplayName"
$AdoDesiredServiceConnectionDescription = "Service connection, via federated identity, to the `"$ServicePrincipalDisplayName`" Entra app registration"

$AdoDesiredServiceConnectionDetails = @{
    'type'                             = 'azurerm'
    'url'                              = 'https://management.azure.com/'
    'name'                             = $AdoDesiredServiceConnectionName
    'description'                      = $AdoDesiredServiceConnectionDescription
    'authorization'                    = @{
        'parameters' = @{
            'tenantid'           = $TenantId
            # "/subscriptions/$SubscriptionId/resourcegroups/$ResourceGroupName" didn't help with 
            # "Synapse workspace deployment@2" not liking federated credential service connections.  
            # Going back to sub-only, since that is more generically useful.
            'scope'              = "/subscriptions/$SubscriptionId"
            'serviceprincipalid' = $ServicePrincipalId
        }
        'scheme'     = 'WorkloadIdentityFederation'
    }
    'data'                             = @{
        'creationMode'     = 'Manual'
        'environment'      = 'AzureCloud'
        'identityType'     = 'AppRegistrationManual'
        'scopeLevel'       = 'Subscription'
        'subscriptionId'   = $SubscriptionId
        'subscriptionName' = $SubscriptionName
    }
    'serviceEndpointProjectReferences' = @(
        @{
            'name'             = $AdoDesiredServiceConnectionName
            'description'      = $AdoDesiredServiceConnectionDescription
            'projectReference' = @{
                'id'   = $AdoProjectId
                'name' = $AdoProject
            }
        }
    )
}

$ADOServiceConnectionId = az devops service-endpoint list `
    --organization $AdoOrg `
    --project $AdoProject `
    --query "[?name=='$AdoDesiredServiceConnectionName'].id" `
    --output 'tsv'

if (-not $ADOServiceConnectionId) {
    $temporary_file_path_sc_details = "tempfilesc.json"
    $AdoDesiredServiceConnectionDetails | ConvertTo-Json -Depth 100 | Out-File $temporary_file_path_sc_details
    $sc = az devops service-endpoint create `
        --organization $AdoOrg `
        --project $AdoProject `
        --service-endpoint-configuration $temporary_file_path_sc_details
    Remove-Item -Path $temporary_file_path_sc_details
    $ADOServiceConnectionId = $sc.id
    Write-Host("Created new ADO service connection")
}
else {
    Write-Host("Found existing ADO service connection")
}