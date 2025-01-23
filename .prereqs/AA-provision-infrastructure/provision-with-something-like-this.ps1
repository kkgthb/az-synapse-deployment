# $GhRepoName = gh repo view --json 'name' --jq '.name'
# $GhOwnerName = gh repo view --json 'owner' --jq '.owner.login'
# $AdoOrgMatch = az devops configure --list | Select-String -Pattern '^organization = (.*)$'
# $AdoOrgName = ((((($AdoOrgMatch)?.Matches)?.Captures)?.Groups)?[1])?.Value
# $AdoProjMatch = az devops configure --list | Select-String -Pattern '^project = (.*)$'
# $AdoProjName = ((((($AdoProjMatch)?.Matches)?.Captures)?.Groups)?[1])?.Value
# $EntraTenantId = az account show --query 'tenantId' --output 'tsv'




# ###############################
# PROVISION "DEV" AZURE RESOURCES
# ###############################

$temporary_dev_file_path_bicep_params = "tempfilebcdev.json"
@{
    "`$schema"       = "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#"
    "contentVersion" = "1.0.0.0"
    "parameters"     = @{
        "envNickname"   = @{"value" = "dev" }
    }
} | ConvertTo-Json -Depth 10 | Out-File $temporary_dev_file_path_bicep_params
az deployment sub create `
    --name 'neurons-infra-dev' `
    --subscription 'Visual Studio Professional Subscription' `
    --location 'centralus' `
    --template-file ([IO.Path]::Combine((Split-Path -Path $PSCommandPath -Parent), 'bicep-definitions', '000.bicep')) `
    --parameters $temporary_dev_file_path_bicep_params
Remove-Item -Path $temporary_dev_file_path_bicep_params




# ###############################
# PROVISION "PRD" AZURE RESOURCES
# ###############################

$temporary_prd_file_path_bicep_params = "tempfilebcprd.json"
@{
    "`$schema"       = "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#"
    "contentVersion" = "1.0.0.0"
    "parameters"     = @{
        "envNickname"   = @{"value" = "prd" }
    }
} | ConvertTo-Json -Depth 10 | Out-File $temporary_prd_file_path_bicep_params
az deployment sub create `
    --name 'neurons-infra-prd' `
    --subscription 'Visual Studio Professional Subscription' `
    --location 'centralus' `
    --template-file ([IO.Path]::Combine((Split-Path -Path $PSCommandPath -Parent), 'bicep-definitions', '000.bicep')) `
    --parameters $temporary_prd_file_path_bicep_params
Remove-Item -Path $temporary_prd_file_path_bicep_params