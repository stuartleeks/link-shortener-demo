import { AzureFunction, Context } from "@azure/functions"
import * as appInsights from "applicationinsights";

appInsights.setup();
const client = appInsights.defaultClient;


const serviceBusQueueTrigger: AzureFunction = async function(context: Context,
    redirectMessage: {path: string, redirectUrl : string}): Promise<void> {
    context.log('ServiceBus queue trigger function processed message', redirectMessage);

    // Log stats to Cosmos DB ... TODO


    client.trackMetric({
        name: "redirect",
        value: 1,
        properties: {   
            path: redirectMessage.path,
            redirectUrl: redirectMessage.redirectUrl
        }
    });


};

export default serviceBusQueueTrigger;