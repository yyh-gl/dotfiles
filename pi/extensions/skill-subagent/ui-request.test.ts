import { describe, expect, test } from "bun:test";
import { buildCtxUiCall } from "./ui-request.ts";

describe("buildCtxUiCall", () => {
	test("method:selectはctx.ui.select用の(title, options)にマッピングされる", () => {
		expect(
			buildCtxUiCall({ type: "extension_ui_request", id: "1", method: "select", title: "質問", options: ["a", "b"] }),
		).toEqual({ method: "select", args: ["質問", ["a", "b"]] });
	});
});
