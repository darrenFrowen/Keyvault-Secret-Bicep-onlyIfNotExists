# Azure Key Vault Secret Management with Bicep `@onlyIfNotExists()` Decorator

This project demonstrates the use of the new experimental **`@onlyIfNotExists()`** decorator in Azure Bicep, which enables idempotent resource deployment by creating resources only if they don't already exist. This is particularly useful for sensitive resources like Key Vault secrets that should not be overwritten once created.

## 🧪 Experimental Feature Overview

The `@onlyIfNotExists()` decorator is an experimental feature introduced in Bicep that allows you to conditionally deploy resources based on their existence. This decorator is especially valuable for:

- **Key Vault Secrets**: Prevent accidental overwriting of existing secrets
- **Database Records**: Avoid duplicate entries in configuration tables
- **One-time Setup Resources**: Resources that should only be created once

### Prerequisites

- Azure CLI or Azure PowerShell installed
- Bicep CLI version that supports experimental features
- Access to an Azure subscription with permissions to create Key Vaults and secrets

## 📋 Project Structure

This repository contains three main files that work together to demonstrate the `@onlyIfNotExists()` functionality:

```text
├── bicepconfig.json     # Bicep configuration file enabling experimental features
├── keyvault.bicep       # Main Bicep template with @onlyIfNotExists() decorator
├── keyvault.ps1         # PowerShell deployment script
└── README.md           # This documentation file
```

## 🔧 File Breakdown and Code Explanations

### 1. `bicepconfig.json` - Configuration File

This file enables the experimental `@onlyIfNotExists()` feature in Bicep:

```json
{
  "analyzers": {
    "core": {
      "rules": {
        "use-recent-module-versions": {
          "level": "warning",
          "message": "The module version is outdated. Please consider updating to the latest version."
        }
      }
    }
  },
  "experimentalFeaturesEnabled": {
    "onlyIfNotExists": true
  }
}
```

**Key Components:**

- **`analyzers.core.rules`**: Configures linting rules for Bicep files
  - `use-recent-module-versions`: Warns when outdated module versions are used
- **`experimentalFeaturesEnabled.onlyIfNotExists`**: **Critical setting** that enables the `@onlyIfNotExists()` decorator
  - Must be set to `true` to use this experimental feature
  - Without this setting, the decorator will not be recognized

### 2. `keyvault.bicep` - Main Bicep Template

This is the core template that demonstrates the `@onlyIfNotExists()` decorator:

```bicep
@description('Key Vault module to create a Key Vault')
module keyvault 'br/public:avm/res/key-vault/vault:0.13.0' = {
  params: {
    name: 'keyvaultName'
  }
}

@description('Reference the existing Keyvault as a resource to be parent')
resource keyvaultExisting 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
    name: 'keyVaultName'
}

@secure()
@description('Generate a new GUID for each deployment - cannot be guessed')
param secretValue string = newGuid()

@description('Secret name indicating the fixed date and time when originally deployed')
param secretName string = 'myKeyVaultSecretName'

@onlyIfNotExists()
@description('Create a secret in the Key Vault only if it does not exist')
resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyvaultExisting
  name: secretName
  dependsOn: [
    keyvault
  ]
  properties: {
    value: secretValue
  }
}
```

**Code Breakdown:**

1. **Module Declaration (`keyvault`)**:
   - Uses Azure Verified Modules (AVM) for Key Vault creation
   - Leverages the public Bicep registry: `br/public:avm/res/key-vault/vault:0.13.0`
   - Creates a new Key Vault with the specified name

2. **Existing Resource Reference (`keyvaultExisting`)**:
   - References an existing Key Vault to use as the parent for the secret
   - Uses the `existing` keyword to indicate this resource already exists
   - **Note**: There's a naming inconsistency here (`keyvaultName` vs `keyVaultName`) that should be aligned

3. **Parameters**:
   - **`secretValue`**:
     - Marked with `@secure()` decorator for sensitive data handling
     - Uses `newGuid()` function to generate a unique value per deployment
     - Ensures the secret value is unpredictable and unique
   - **`secretName`**:
     - Defines the name of the secret to be created
     - Defaults to `'myKeyVaultSecretName'`

4. **The Key Feature - `@onlyIfNotExists()` Decorator**:
   - **Purpose**: Ensures the secret is only created if it doesn't already exist
   - **Behavior**:
     - On first deployment: Creates the secret with the generated GUID
     - On subsequent deployments: Skips creation if the secret already exists
     - Prevents accidental overwriting of existing secrets
   - **Use Cases**: Perfect for passwords, API keys, or any sensitive data that shouldn't be regenerated

5. **Resource Definition (`secret`)**:
   - **Parent Relationship**: Uses `parent: keyvaultExisting` to establish hierarchy
   - **Dependencies**: Explicitly depends on the Key Vault module creation
   - **Properties**: Sets the secret value using the secure parameter

### 3. `keyvault.ps1` - PowerShell Deployment Script

This script handles the deployment process using Azure PowerShell:

```powershell
# Login to Azure Tenant and Subscription
Connect-AzAccount -TenantId 'tenantId' -SubscriptionId 'subscriptionId'

# Resource Group Name
$ResourceGroupName = "resourcGroupName"
# Set the location for the deployment
$location = "UK South"
# Set the path to your Bicep file
$templateFile = "./keyvault.bicep"

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
```

**Script Breakdown:**

1. **Authentication**:
   - `Connect-AzAccount`: Authenticates to Azure with specific tenant and subscription
   - **Important**: Replace `'tenantId'` and `'subscriptionId'` with actual values

2. **Configuration Variables**:
   - **`$ResourceGroupName`**: Target resource group for deployment
   - **`$location`**: Azure region for resource group creation
   - **`$templateFile`**: Path to the Bicep template file

3. **Resource Group Management**:
   - Checks if the resource group exists using `Get-AzResourceGroup`
   - Creates the resource group if it doesn't exist
   - Uses error handling with `SilentlyContinue` to avoid script termination

4. **Deployment Process**:
   - **Dynamic Naming**: Creates unique deployment names with timestamp
   - **`New-AzResourceGroupDeployment`**: Executes the Bicep template
   - **Verbose Output**: Provides detailed deployment information
   - **Success Notification**: Displays completion message in green

## 🚀 How to Use This Project

### Step 1: Update Configuration Values

Before deploying, update the following placeholders in the files:

1. **In `keyvault.ps1`**:

   ```powershell
   Connect-AzAccount -TenantId 'tenantId' -SubscriptionId 'subscriptionId'
   $ResourceGroupName = "resourcGroupName"
   ```

2. **In `keyvault.bicep`**:

   ```bicep
   # Update the Key Vault name to be unique
   module keyvault 'br/public:avm/res/key-vault/vault:0.13.0' = {
     params: {
       name: 'keyvaultName'
     }
   }
   
   # Ensure this matches the name above
   resource keyvaultExisting 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
       name: 'keyvaultName'
   }
   ```

### Step 2: Deploy the Template

Run the PowerShell script:

```powershell
.\keyvault.ps1
```

### Step 3: Verify the Deployment

1. **First Deployment**:
   - Key Vault is created
   - Secret is created with a new GUID value
   - Note the secret value from the portal

2. **Second Deployment**:
   - Key Vault already exists (no changes)
   - Secret creation is skipped due to `@onlyIfNotExists()`
   - Original secret value is preserved, check in portal

## 📚 Key Benefits of `@onlyIfNotExists()`

### 1. **Idempotency**

- Multiple deployments don't overwrite existing resources
- Safe to run deployment scripts repeatedly

### 2. **Security**

- Prevents accidental regeneration of sensitive values
- Maintains secret integrity across deployments
- Secret value cannot be guessed using unique new GUID value

## 🔍 Use Cases and Best Practices

### Ideal Use Cases

1. **Database Connection Strings**: Create once, use everywhere
2. **API Keys and Tokens**: Prevent regeneration that breaks integrations
3. **Encryption Keys**: Maintain data accessibility
4. **Service Principal Secrets**: Avoid breaking automated processes
5. **Configuration Values**: Preserve environment-specific settings

### Best Practices

1. **Always use with `@secure()` for sensitive data**
2. **Implement proper naming conventions for secrets**
3. **Use meaningful descriptions with `@description()`**
4. **Test in development environment first**
5. **Document secret purposes and rotation policies**
6. **Combine with Azure Key Vault access policies**

## ⚠️ Important Notes and Limitations

### Experimental Feature Warnings

- **Feature is experimental**: May change or be removed in future versions
- **Production Use**: Evaluate thoroughly before production deployment
- **Breaking Changes**: Microsoft may introduce breaking changes
- **Documentation**: Limited official documentation available

### Current Limitations

1. **Bicep Version**: Requires specific Bicep CLI version with experimental support
2. **IDE Support**: IntelliSense may not recognize the decorator
3. **Error Handling**: Limited error messaging for decorator issues
4. **Resource Types**: May not work with all Azure resource types

### Troubleshooting

- **Decorator not recognized**: Ensure `bicepconfig.json` has the correct experimental feature enabled
- **Compilation errors**: Verify Bicep CLI version supports experimental features
- **Permission errors**: Check Azure RBAC permissions for Key Vault operations

## 📖 References and Documentation

- [Azure Verified Modules](https://aka.ms/avm)
- [Azure Verified Module Azure Key Vault](https://github.com/Azure/bicep-registry-modules/blob/main/avm/res/key-vault/vault/README.md)
- [GitHub PR: Add onlyIfNotExistsDecorator](https://github.com/Azure/bicep/pull/16655)
- [Bicep Experimental Features](https://aka.ms/bicep/experimental-features)


## 🤝 Contributing

This project demonstrates experimental Bicep features. If you find issues or have improvements:

1. Test changes in a development environment
2. Document any modifications clearly
3. Share feedback with the Bicep community
4. Report bugs through appropriate channels

---

**⚡ Quick Start**: Clone this repo, update the configuration values, and run `.\keyvault.ps1` to see the `@onlyIfNotExists()` decorator in action!
