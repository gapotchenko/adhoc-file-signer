import { executeCgiScript } from "./cgi.ts";

export async function tryDispatchCall(
  request: Request,
  call: string | undefined,
): Promise<Response | undefined> {
  switch (call) {
    case "ping":
      return await handlePingCall(request);
    case "capabilities":
      return await handleCapabilitiesCall(request);
    case "echo-file":
      return await handleEchoFileCall(request);
    case "sign-file":
      return await handleSignFileCall(request);
    default:
      return undefined;
  }
}

/** Ensures that CGI gateway is working. */
async function handlePingCall(request: Request): Promise<Response> {
  return await executeCgiScript(request, "cgi-ping.sh");
}

/** Gets server capabilities. */
async function handleCapabilitiesCall(request: Request): Promise<Response> {
  return await executeCgiScript(request, "cgi-capabilities.sh");
}

/** Echoes back the received file. */
function handleEchoFileCall(request: Request): Promise<Response> {
  return cgiFileTransform(request, "cat");
}

/** Signs the file.  */
function handleSignFileCall(request: Request): Promise<Response> {
  return cgiFileTransform(request, "sign-file.sh");
}

async function cgiFileTransform(
  request: Request,
  command: string,
): Promise<Response> {
  if (request.method !== "POST") {
    return new Response("405 Method Not Allowed", { status: 405 });
  }

  return await executeCgiScript(
    request,
    `cgi-error-trap.sh -- cgi-file-transform.sh -- ${command}`,
    { streaming: true },
  );
}
