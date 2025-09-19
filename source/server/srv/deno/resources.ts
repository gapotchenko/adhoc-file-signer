import { join, resolve } from "@std/path";

export function getAppDir(): string {
  return appDir;
}

const appDir = resolve(join(import.meta.dirname ?? ".", "../.."));
