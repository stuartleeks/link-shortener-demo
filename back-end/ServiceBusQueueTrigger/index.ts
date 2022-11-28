import { AzureFunction, Context } from "@azure/functions"
import * as appInsights from "applicationinsights";

appInsights.setup();
const client = appInsights.defaultClient;

const serviceBusQueueTrigger: AzureFunction = async function (
    context: Context,
    redirectMessage: { path: string, redirectUrl: string }
): Promise<void> {
    context.log(`Process service bus message. Path=${redirectMessage.path}`);

    context.log(`Write custom metric to Application Insights`);
    client.trackMetric({
        name: "redirect",
        value: 1,
        properties: { path: redirectMessage.path, redirectUrl: redirectMessage.redirectUrl },
    });
    client.flush(); // demo aid - don't do this!

    context.log(`Send SignalR message`);
    context.bindings.signalRMessages = [{
        target: "redirect",
        arguments: [redirectMessage.path, redirectMessage.redirectUrl]
    }];
};

export default serviceBusQueueTrigger;
