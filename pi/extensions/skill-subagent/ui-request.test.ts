import { describe, expect, test } from "bun:test";
import { buildCtxUiCall } from "./ui-request.ts";

describe("buildCtxUiCall", () => {
	test("method:selectはctx.ui.select用の(title, options)にマッピングされる", () => {
		expect(
			buildCtxUiCall({ type: "extension_ui_request", id: "1", method: "select", title: "質問", options: ["a", "b"] }),
		).toEqual({ method: "select", args: ["質問", ["a", "b"]] });
	});

	test("method:confirmはctx.ui.confirm用の(title, message)にマッピングされる", () => {
		expect(
			buildCtxUiCall({ type: "extension_ui_request", id: "1", method: "confirm", title: "タイトル", message: "本当に?" }),
		).toEqual({ method: "confirm", args: ["タイトル", "本当に?"] });
	});

	test("method:inputはctx.ui.input用の(title, placeholder)にマッピングされる", () => {
		expect(
			buildCtxUiCall({ type: "extension_ui_request", id: "1", method: "input", title: "入力", placeholder: "例" }),
		).toEqual({ method: "input", args: ["入力", "例"] });
	});

	test("method:inputでplaceholder省略時はundefinedのまま渡る", () => {
		expect(buildCtxUiCall({ type: "extension_ui_request", id: "1", method: "input", title: "入力" })).toEqual({
			method: "input",
			args: ["入力", undefined],
		});
	});

	test("method:editorはctx.ui.editor用の(title, prefill)にマッピングされる", () => {
		expect(
			buildCtxUiCall({ type: "extension_ui_request", id: "1", method: "editor", title: "編集", prefill: "下書き" }),
		).toEqual({ method: "editor", args: ["編集", "下書き"] });
	});

	test.each([
		[{ type: "extension_ui_request" as const, id: "1", method: "notify" as const, message: "お知らせ" }],
		[{ type: "extension_ui_request" as const, id: "1", method: "setStatus" as const, statusKey: "k", statusText: "t" }],
		[
			{
				type: "extension_ui_request" as const,
				id: "1",
				method: "setWidget" as const,
				widgetKey: "k",
				widgetLines: ["a"],
			},
		],
		[{ type: "extension_ui_request" as const, id: "1", method: "setTitle" as const, title: "タイトル" }],
		[{ type: "extension_ui_request" as const, id: "1", method: "set_editor_text" as const, text: "テキスト" }],
	])("応答不要なmethod(%p)はnoneと判定される", (request) => {
		expect(buildCtxUiCall(request)).toEqual({ method: "none" });
	});

	test("未知のmethod文字列はnone(応答不要)と判定される", () => {
		const request = { type: "extension_ui_request", id: "1", method: "unknown_future_method" } as Parameters<
			typeof buildCtxUiCall
		>[0];
		expect(buildCtxUiCall(request)).toEqual({ method: "none" });
	});
});
