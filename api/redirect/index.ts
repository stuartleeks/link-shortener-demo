import { AzureFunction, Context, HttpRequest } from "@azure/functions"

const redirects = {
    "/swa": "https://learn.microsoft.com/en-us/azure/static-web-apps/overview",
    "/functions": "https://learn.microsoft.com/en-us/azure/azure-functions/functions-overview",
    "/service-bus": "https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-overview",
    "/signalr": "https://learn.microsoft.com/en-us/azure/azure-signalr/signalr-overview",
    "/microsoft": "https://microsoft.com",
    "/stuartleeks": "https://stuartleeks.com",
    "/jamiedalton": "https://jamied.me/about/",
    "/wsl": "https://wsl.tips",
}

const httpTrigger: AzureFunction = async function (context: Context, req: HttpRequest): Promise<void> {
    context.log('HTTP trigger function processed a request.');

    const originalUrl = req.headers['x-ms-original-url'] ?? "https://stuartleeks.com";
    const originalPath = new URL(originalUrl).pathname;
    const redirectUrl = redirects[originalPath];
    
    // send message to Service Bus
    context.bindings.redirectQueue = {
        path: originalPath,
        redirectUrl
    };

    // send response
    context.res = {
        status: 302, /* Defaults to 200 */
        body: "nothing to see here..",
        headers: {
            Location: redirectUrl
    }
    };
};

export default httpTrigger;