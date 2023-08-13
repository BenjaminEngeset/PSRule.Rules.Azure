param vaultName string = 'DefaultValue'
param skuName string = 'DefaultValue'
param skuTier string = 'DefaultValue'
param location string = 'location'

resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2023-01-01' = {
  name: vaultName
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    securitySettings: {
      immutabilitySettings: {
        state: 'Locked'
      }
    }
  }
}
