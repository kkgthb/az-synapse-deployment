$SubscriptionName = 'Visual Studio Professional Subscription'
$SolutionName = 'neurons'
$Location = 'centralus'
$ResourceGroupName = "$SolutionName-rg-$EnvNickname"
$SynapseWorkspaceName = "$SolutionName-sw-$EnvNickname"
$EnvNickname = 'prd'

$LinkedServiceExpectedData = @{
    'name'       = "Example link to a key vault"
    'type'       = 'Microsoft.Synapse/workspaces/linkedservices'
    'properties' = @{
        'type'           = 'AzureKeyVault'
        'typeProperties' = @{
            'baseUrl' = "https://$SolutionName-kv-@{linkedService().kv_current_env}.vault.azure.net/"
        }
        'parameters'     = @{
            'kv_current_env' = @{
                'type'         = 'string'
                'defaultValue' = $EnvNickname
            }
        }
    }
}
$LinkedServiceId = az synapse linked-service list `
    --subscription $SubscriptionName `
    --workspace-name $SynapseWorkspaceName `
    --query "[?name=='$($LinkedServiceExpectedData.name)'].id" `
    --output 'tsv'
if (-not $LinkedServiceId) {
    $temporary_file_path_ls_details = "tempfilels.json"
    $LinkedServiceExpectedData | ConvertTo-Json -Depth 100 | Out-File $temporary_file_path_ls_details
    $ls = az synapse linked-service create `
        --subscription $SubscriptionName `
        --workspace-name $SynapseWorkspaceName `
        --name $LinkedServiceExpectedData.name `
        --file "@$($temporary_file_path_ls_details)"
    Remove-Item -Path $temporary_file_path_ls_details
    $LinkedServiceId = $ls.id
    Write-Host("Created new linked service")
}
else {
    Write-Host("Found existing linked service")
}


$PipelineExpectedData = @{
    'name'        = 'My First Pipeline'
    'type'        = 'Microsoft.Synapse/workspaces/pipelines'
    'description' = 'I am a pipeline that makes a call out to Postman Echo'
    'properties'  = @{
        'activities' = @(
            @{
                'name'           = 'Demo Web Call'
                'type'           = 'WebActivity'
                'description'    = 'I am a web call.  Yay.'
                'typeProperties' = @{
                    'method'     = 'GET'
                    'url'        = @{
                        'type'  = 'Expression'
                        'value' = 'https://postman-echo.com/get?hello=@{pipeline().Pipeline}'
                    }
                    'authentication' = @{
                        'type'     = 'Basic'
                        'username' = 'username_would_go_here'
                        'password' = @{
                            'type'       = 'AzureKeyVaultSecret'
                            'secretName' = 'flavor'
                            'store'      = @{
                                'type'          = 'LinkedServiceReference'
                                'referenceName' = ($LinkedServiceExpectedData.name)
                                'parameters' = @{
                                    "$($LinkedServiceExpectedData.properties.parameters.Keys[0])" = "$($LinkedServiceExpectedData.properties.parameters.Values[0].defaultValue)"
                                }
                            }
                        }
                    }
                }
            }
        )
    }
}
$PipelineId = az synapse pipeline list `
    --subscription $SubscriptionName `
    --workspace-name $SynapseWorkspaceName `
    --query "[?name=='$($PipelineExpectedData.name)'].id" `
    --output 'tsv'
if (-not $PipelineId) {
    $temporary_file_path_pl_details = "tempfilepl.json"
    $PipelineExpectedData | ConvertTo-Json -Depth 100 | Out-File $temporary_file_path_pl_details
    $pl = az synapse pipeline create `
        --subscription $SubscriptionName `
        --workspace-name $SynapseWorkspaceName `
        --name $PipelineExpectedData.name `
        --file "@$($temporary_file_path_pl_details)"
    Remove-Item -Path $temporary_file_path_pl_details
    $PipelineId = $pl.id
    Write-Host("Created new pipeline")
}
else {
    Write-Host("Found existing pipeline")
}

# No Bicep for Synapse RBAC role assignments, apparently.
# https://github.com/Azure/ResourceModules/issues/1972
# az synapse role assignment list  --workspace-name 'x' --subscription 'z' --assignee{-object-id} 'OBJECT-ID-NOT-APP-ID' --scope 'TODO' --role 'nameisokayhere'
# az synapse role assignment create  --workspace-name 'x' --subscription 'z' --assignee{-object-id} 'OBJECT-ID-NOT-APP-ID' --assignee-principal-type 'ServicePrincipal' --assignment-id 'optional-handmade-guid' --scope 'TODO' --role 'nameisokayhere'
# No update command, but yes it has a Delete command.  (And a show, but like the others, only takes an ID, so not terribly useful.)

# No global parameters yet
# https://learn.microsoft.com/en-us/answers/questions/145623/global-parameters-in-azure-synapse-workspace

# Maybe the ClientIpAddressNotAuthorized error is _my_ actual workstation?
# https://stackoverflow.com/questions/78728272/azure-devops-release-pipeline-has-suddenly-started-failing
# https://www.google.com/search?q=ClientIpAddressNotAuthorized
# https://learn.microsoft.com/en-us/answers/questions/1791964/error-while-creating-linked-service-from-synapse-t shows some promise, but it's late and I already killed off the RG for cost.


# Doesn't seem there's a Pipeline bicep, either.
# az synapse pipeline show --workspace-name 'x' --name 'y' --subscription 'z'
# az synapse pipeline create --file @"temp_json_file_path_goes_here.json" --workspace-name 'x' --name 'y' --subscription 'z'
# az synapse pipeline update --file @"temp_json_file_path_goes_here.json" --workspace-name 'x' --name 'y' --subscription 'z'

