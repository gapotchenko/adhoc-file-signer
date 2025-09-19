import { join } from "@std/path";
import { executeCgi } from "@gapotchenko/deno-cgi";
import { getAppDir } from "./resources.ts";

export type CgiScriptExecutionOptions = {
  streaming?: boolean;
};

export async function executeCgiScript(
  request: Request,
  script: string,
  options: CgiScriptExecutionOptions = {},
): Promise<Response> {
  const appDir = getAppDir();
  const env = {
    APP_LIB_PATH: join(appDir, "lib"),
    APP_SRV_CGI_PATH: join(appDir, "srv/cgi"),
    APP_USR_BIN_PATH: join(appDir, "usr/bin"),
  };

  script =
    `export PATH="$PATH:$APP_LIB_PATH:$APP_SRV_CGI_PATH:$APP_USR_BIN_PATH"; ${script}`;

  let shell = "/bin/sh";
  let shellArgs = ["-eu", "-c"];

  if (Deno.build.os === "windows") {
    shellArgs = ["-i", "-l", shell, ...shellArgs];
    shell = "gnu-tk";
  }

  return await executeCgi(
    request,
    shell,
    [...shellArgs, script],
    {
      streaming: options.streaming,
      env,
    },
  );
}
