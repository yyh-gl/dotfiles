import { describe, expect, test } from "bun:test";
import { buildCtxUiCall, buildUiResponse } from "./ui-request.ts";

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

	test("method:notifyはctx.ui.notify用の(message, notifyType)にマッピングされる", () => {
		expect(
			buildCtxUiCall({ type: "extension_ui_request", id: "1", method: "notify", message: "お知らせ", notifyType: "warning" }),
		).toEqual({ method: "notify", args: ["お知らせ", "warning"] });
	});

	test("method:notifyでnotifyType省略時はundefinedのまま渡る", () => {
		expect(buildCtxUiCall({ type: "extension_ui_request", id: "1", method: "notify", message: "お知らせ" })).toEqual({
			method: "notify",
			args: ["お知らせ", undefined],
		});
	});

	test.each([
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

describe("buildUiResponse", () => {
	test("select/inputの結果が文字列ならvalueを持つレスポンスになる", () => {
		expect(buildUiResponse("1", "選択肢A")).toEqual({ type: "extension_ui_response", id: "1", value: "選択肢A" });
	});

	test("confirmの結果がbooleanならconfirmedを持つレスポンスになる", () => {
		expect(buildUiResponse("1", true)).toEqual({ type: "extension_ui_response", id: "1", confirmed: true });
	});

	test("ユーザーがキャンセル(undefined)した場合はcancelledを持つレスポンスになる", () => {
		expect(buildUiResponse("1", undefined)).toEqual({ type: "extension_ui_response", id: "1", cancelled: true });
	});

	test("idはrequest.idをそのまま転記する", () => {
		expect(buildUiResponse("リクエストID-42", "value")).toEqual({
			type: "extension_ui_response",
			id: "リクエストID-42",
			value: "value",
		});
	});
});
