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
    context.log("Redirect function processed a request.");

    const originalUrl = req.headers["x-ms-original-url"] as string;
    const originalPath = new URL(originalUrl).pathname;
    const redirectUrl = redirects[originalPath] ?? "https://stuartleeks.com";

    context.log("Sending message to queue");
    context.bindings.redirectQueue = {
        path: originalPath,
        redirectUrl
    };

    context.res = {
        status: 302,
        headers: {
            "Location": redirectUrl
        }
    };

};

export default httpTrigger;