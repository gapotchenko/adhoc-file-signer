import { timingSafeEqual } from "@std/crypto/timing-safe-equal";
import { tryDispatchCall } from "./calls.ts";

export default {
  fetch: handleRequest,
} satisfies Deno.ServeDefaultExport;

async function handleRequest(request: Request): Promise<Response> {
  const url = new URL(request.url);

  // ---- Routing

  //console.log(url);

  const match = router.exec(url);
  if (!match) return createNotFoundResponse();

  const app = match.pathname.groups["app"];

  if (app !== slug) return createNotFoundResponse();
  const call = match.pathname.groups["call"];

  if (call === undefined) {
    // Allows a client to reliably detect location redirections using a single 'curl' call.
    // 4xx would make 'curl' fail.
    return new Response(null, { status: 204 });
  }

  // ---- Authorization

  const actualApiKey = url.searchParams.get("apiKey");
  if (!actualApiKey) {
    return createForbiddenResponse();
  }

  const expectedApiKey = apiKey;
  if (!expectedApiKey) {
    return createForbiddenResponse();
  }

  const textEncoder = new TextEncoder();
  if (
    !timingSafeEqual(
      textEncoder.encode(actualApiKey),
      textEncoder.encode(expectedApiKey),
    )
  ) {
    return createForbiddenResponse();
  }

  // ---- Call dispatch

  return await tryDispatchCall(request, call) ?? createNotFoundResponse();
}

const router = new URLPattern({ pathname: "/:app/:call?/:rest*" });

function createNotFoundResponse(): Response {
  return new Response("404 Not Found", { status: 404 });
}

function createForbiddenResponse(): Response {
  return new Response("403 Forbidden", { status: 403 });
}

const apiKey = Deno.env.get("GP_ADHOC_FILE_SIGNER_API_KEY");

const slug = Deno.env.get("GP_ADHOC_FILE_SIGNER_SERVER_HTTP_SLUG") ||
  "adhoc-file-signer";
