
# Login to Azure Tenant and Subscription
Connect-AzAccount -TenantId 'tenantId' -SubscriptionId 'subscriptionId'

# Resource Group Name
$ResourceGroupName                      = "resourcGroupName"
# Set the location for the deployment
$location                               = "UK South"
# Set the path to your Bicep file
$templateFile                           = "./keyvault.bicep"

# Create resource group if it doesn't exist
if (-not (Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location
}

# Deploy the Bicep template
$deploymentName = "KeyVault-$(Get-Date -Format 'yyyyMMdd-HHmm')"
New-AzResourceGroupDeployment   -Name $deploymentName `
                                -ResourceGroupName $ResourceGroupName `
                                -TemplateFile $templateFile `
                                -Verbose
Write-Host "Deployment completed!" -ForegroundColor Green