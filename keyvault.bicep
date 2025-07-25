

@description('Key Vault module to create a Key Vault')
module keyvault 'br/public:avm/res/key-vault/vault:0.13.0' = {
  params: {
    name: 'keyvaultName'
  }
}

@description('Referance the existing Keyvault as a resource to be parent ')
resource keyvaultExisting 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
    name: 'keyVaultName'
}

@secure()
@description('Generate a new GUID for each deployment - cannot be guessed')
param secretValue string = newGuid()

@description('Secret name indicating the fixed date and time when originally deployed')
param secretName string = 'vmPasswordSecret'

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
