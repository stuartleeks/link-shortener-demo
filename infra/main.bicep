targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))


// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'demo-${resourceToken}'
  location: location
}


module redirector './redirector.bicep' = {
  name: 'web'
  scope: rg
  params: {
    resourceToken: resourceToken
    location: location
  }
}


output apiServiceBusConnectionString string = redirector.outputs.apiServiceBusConnectionString
output webName string = redirector.outputs.webName
output webBaseUrl string = redirector.outputs.webBaseUrl
output webDeployToken string = redirector.outputs.webDeployToken
output backendFunctionName string = redirector.outputs.backendFunctionName
output backendFunctionStorageConnectionString string = redirector.outputs.backendFunctionStorageConnectionString
output backendServiceBusConnectionString string = redirector.outputs.apiServiceBusConnectionString
output signalrConnectionString string = redirector.outputs.signalrConnectionString
output appInsightsInstrumentationKey string = redirector.outputs.appInsightsInstrumentationKey
output appInsightsConnectionString string = redirector.outputs.appInsightsConnectionString

