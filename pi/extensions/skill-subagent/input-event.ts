import type { InputSource } from "@earendil-works/pi-coding-agent";

export function shouldIgnoreInputEvent(source: InputSource): boolean {
	return source === "extension";
}
