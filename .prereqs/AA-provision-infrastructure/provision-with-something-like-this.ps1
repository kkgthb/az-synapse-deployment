# ###############################
# PROVISION "PRD" AZURE RESOURCES
# ###############################

$temporary_file_path_bicep_params = "tempfilebc.json"
@{
    "`$schema"       = "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#"
    "contentVersion" = "1.0.0.0"
    "parameters"     = @{
        "envNickname" = @{"value" = "prd" }
        "thisRepoName" = @{"value" = (gh repo view --json 'name' --jq '.name')}
        "thisRepoOwner" = @{"value" = (gh repo view --json 'owner' --jq '.owner.login')}
    }
} | ConvertTo-Json | Out-File $temporary_file_path_bicep_params
az deployment sub create `
    --name 'neurons-infra-prd' `
    --subscription 'Visual Studio Professional Subscription' `
    --location 'centralus' `
    --template-file ([IO.Path]::Combine((Split-Path -Path $PSCommandPath -Parent), 'bicep-definitions', '000.bicep')) `
    --parameters $temporary_file_path_bicep_params
Remove-Item -Path $temporary_file_path_bicep_params