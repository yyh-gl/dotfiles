import type { RpcExtensionUIRequest, RpcExtensionUIResponse } from "@earendil-works/pi-coding-agent";

export type CtxUiCall =
	| { method: "select"; args: [string, string[]] }
	| { method: "confirm"; args: [string, string] }
	| { method: "input"; args: [string, string | undefined] }
	| { method: "editor"; args: [string, string | undefined] }
	| { method: "none" };

export function buildCtxUiCall(request: RpcExtensionUIRequest): CtxUiCall {
	switch (request.method) {
		case "select":
			return { method: "select", args: [request.title, request.options] };
		case "confirm":
			return { method: "confirm", args: [request.title, request.message] };
		case "input":
			return { method: "input", args: [request.title, request.placeholder] };
		case "editor":
			return { method: "editor", args: [request.title, request.prefill] };
		default:
			return { method: "none" };
	}
}
