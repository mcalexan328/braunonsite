@description('Application suffix that will be applied to all resources')
param appSuffix string = uniqueString(resourceGroup().id)

@description('The location to deploy all my resources')
param location string = resourceGroup().location

@description('The name of the log analytics workspace')
param logAnalyticsWorkspaceName string = 'log-${appSuffix}'

@description('The name of the Application Insights workspace')
param appInsightsName string = 'appinsights-${appSuffix}'

@description('The name of the Container App Environment')
param containerAppEnvironmentName string = 'env${appSuffix}'

@description('The container image to be used')
param containerImage string = 'braunonsite.azurecr.io/webserver:v1'

@secure()
param keyVaultName string
@secure()
param acrPasswordSecretName string
@secure()
param keyvaultuser string


var containerAppName = 'braunwebsite'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource appInsights 'microsoft.insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource env 'Microsoft.App/managedEnvironments@2023-08-01-preview' = {
  name: containerAppEnvironmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

resource containerApp 'Microsoft.App/containerApps@2023-08-01-preview' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: env.id
    configuration: {
      secrets: [
        {
          name: keyvaultuser
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${acrPasswordSecretName})'
        }
      ]
      registries: [
        {
          server: 'braunonsite.azurecr.io'
          username: 'braunonsite'
          passwordSecretRef: 'acr-password'
        }
      ]
      ingress: {
        external: true
        targetPort: 80
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
    }
    template: {
      containers: [
        {
          name: containerAppName
          image: containerImage
          resources: {
            cpu: 1
            memory: '2.0Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 2
      }
    }
  }
}
