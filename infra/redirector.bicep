param location string = resourceGroup().location
param resourceToken string

//
// App Insights etc
//

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: 'la-${resourceToken}'
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'ai-${resourceToken}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

//
// Service Bus
//
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: 'sb-${resourceToken}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {}
}

resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' = {
  parent: serviceBusNamespace
  name: 'redirects'
  properties: {
    lockDuration: 'PT5M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    deadLetteringOnMessageExpiration: false
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: false
    enableExpress: false
  }
}

// TODO Set up managed identity
resource serviceBusQueueFrontEnd 'Microsoft.ServiceBus/namespaces/queues/authorizationRules@2022-01-01-preview' = {
  name: 'fe-connect'
  parent: serviceBusQueue
  properties: {
    rights: [
      'Manage'
      'Listen'
      'Send'
    ]
  }
}
// TODO Set up managed identity
resource serviceBusQueueBackEnd 'Microsoft.ServiceBus/namespaces/queues/authorizationRules@2022-01-01-preview' = {
  name: 'be-connect'
  parent: serviceBusQueue
  properties: {
    rights: [
      'Manage'
      'Listen'
      'Send'
    ]
  }
}

//
// SignalR
//
resource signalr 'Microsoft.SignalRService/signalR@2022-02-01' = {
  name: 'sr-${resourceToken}'
  location: location
  sku: {
    name: 'Free_F1'
  }
  properties: {
    cors: {
      allowedOrigins: [
        '*'
      ]
    }
  }
}

//
// Static Web App
//

param webSku object = {
  name: 'Free'
  tier: 'Free'
}

resource web 'Microsoft.Web/staticSites@2022-03-01' = {
  name: 'web-${resourceToken}'
  location: location
  sku: webSku
  properties: {
    provider: 'Custom'
  }
}

resource webFuncAppSettings 'Microsoft.Web/staticSites/config@2022-03-01' = {
  name: 'functionappsettings'
  kind: 'string'
  parent: web
  properties: {
    test: 'test-funcappsetting'
    APPINSIGHTS_INSTRUMENTATIONKEY: applicationInsights.properties.InstrumentationKey
    APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString
    ServiceBus: serviceBusQueueFrontEnd.listKeys().primaryConnectionString
    AzureSignalRConnectionString: signalr.listKeys().primaryConnectionString
  }
}

//
// Back-end Function
// 
resource backendFunctionStorage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: 'besa${resourceToken}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}
var backendFunctionStorageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${backendFunctionStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${backendFunctionStorage.listKeys().keys[0].value}'

resource backendFunctionPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'beplan-${resourceToken}'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: true
  }
}
resource backendFunction 'Microsoft.Web/sites@2022-03-01' = {
  name: 'be-${resourceToken}'
  location: location
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: backendFunctionPlan.id
    siteConfig: {
      linuxFxVersion: 'node|16'
      alwaysOn: false
      ftpsState: 'FtpsOnly'
      appCommandLine: ''
      // numberOfWorkers: null //
      // minimumElasticInstanceCount: null
      use32BitWorkerProcess: false
      // functionAppScaleLimit: null
    }
    clientAffinityEnabled: false
    httpsOnly: true
  }

  // identity: { type: managedIdentity ? 'SystemAssigned' : 'None' }

  resource configAppSettings 'config' = {
    name: 'appsettings'
    properties: {
      APPINSIGHTS_INSTRUMENTATIONKEY: applicationInsights.properties.InstrumentationKey
      APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString
      AzureWebJobsServiceBus: serviceBusQueueBackEnd.listKeys().primaryConnectionString
      AzureSignalRConnectionString: signalr.listKeys().primaryConnectionString
      AzureWebJobsStorage: backendFunctionStorageConnectionString
      FUNCTIONS_EXTENSION_VERSION: '~4'
      FUNCTIONS_WORKER_RUNTIME: 'node'
    }
  }

  resource configLogs 'config' = {
    name: 'logs'
    properties: {
      applicationLogs: { fileSystem: { level: 'Verbose' } }
      detailedErrorMessages: { enabled: true }
      failedRequestsTracing: { enabled: true }
      httpLogs: { fileSystem: { enabled: true, retentionInDays: 1, retentionInMb: 35 } }
    }
    dependsOn: [
      configAppSettings
    ]
  }
}

//
// Outputs
//
#disable-next-line outputs-should-not-contain-secrets
output apiServiceBusConnectionString string = serviceBusQueueFrontEnd.listKeys().primaryConnectionString
#disable-next-line outputs-should-not-contain-secrets
output backendServiceBusConnectionString string = serviceBusQueueBackEnd.listKeys().primaryConnectionString
output webName string = web.name
output webBaseUrl string = 'https://${web.properties.defaultHostname}'
#disable-next-line outputs-should-not-contain-secrets
output webDeployToken string = web.listSecrets().properties.apiKey
output backendFunctionName string = backendFunction.name
output backendFunctionStorageConnectionString string = backendFunctionStorageConnectionString
#disable-next-line outputs-should-not-contain-secrets
output signalrConnectionString string = signalr.listKeys().primaryConnectionString
output appInsightsInstrumentationKey string = applicationInsights.properties.InstrumentationKey
output appInsightsConnectionString string = applicationInsights.properties.ConnectionString
