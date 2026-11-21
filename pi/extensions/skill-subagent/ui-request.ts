import type { RpcExtensionUIRequest, RpcExtensionUIResponse } from "@earendil-works/pi-coding-agent";

export type CtxUiCall =
	| { method: "select"; args: [string, string[]] }
	| { method: "confirm"; args: [string, string] }
	| { method: "input"; args: [string, string | undefined] }
	| { method: "editor"; args: [string, string | undefined] }
	| { method: "none" };

export function buildUiResponse(id: string, result: string | boolean | undefined): RpcExtensionUIResponse {
	if (result === undefined) return { type: "extension_ui_response", id, cancelled: true };
	if (typeof result === "boolean") return { type: "extension_ui_response", id, confirmed: result };
	return { type: "extension_ui_response", id, value: result };
}

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
