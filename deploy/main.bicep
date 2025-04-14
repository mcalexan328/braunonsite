@description('Application suffix that will be applied to all resources')
param appSuffix string = uniqueString(resourceGroup().id)

@description('The location to deploy all my resources')
param location string = resourceGroup().location

@description('The name of the log analytics workspace')
param loganalyticsWorkspaceName string = 'log-${appSuffix}'

@description('The name of the Application Insights Workspace')
param appInsightsName string = 'appinsights-${appSuffix}'

@description('The name of the Container App Environment')
param containerAppEnvironmentName string = 'env-${appSuffix}'

var containerAppName = 'Braun'

resource loganalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: loganalyticsWorkspaceName
  location: location
  sku: {
    name: 'PerGB2018'
  }
  properties: {
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
    Ingestion_Azure_Resource_Region: location
    WorkspaceResourceId: loganalytics.id
  }
}

resource env 'Microsoft.App/connectedEnvironments@2024-10-02-preview' = {
  name: containerAppEnvironmentName
  location: location
  properties: {
    appLogsConfiguration: {
      logAnalyticsConfiguration: {
        customerId: loganalytics.properties.customerId
        sharedKey: loganalytics.listKeys().primarySharedKey
      }
    }
  }
}

resource containerApp 'Microsoft.App/containerApps@2024-10-02-preview' = {
  name: containerAppName
  location: location
  properties: {
    environmentId: env.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
        traffic: [
          {
            revisionName: true
            weight: 100
          }
        ]
      }
    }
    template: {
      containers: [
        {
          name: containerAppName
          properties: {
            image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
            resources: {
              cpu: json('1.0')
              memory: '1.0Gi'
            }
          }
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 3
        }
      }
    }
  }
