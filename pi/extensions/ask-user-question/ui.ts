import type { ExtensionToolContext } from "@earendil-works/pi-coding-agent";
import { Editor, type EditorTheme, Key, matchesKey, visibleWidth, wrapTextWithAnsi } from "@earendil-works/pi-tui";

export interface QuestionOptionInput {
	label: string;
	description?: string;
}

export interface QuestionInput {
	question: string;
	header: string;
	options: QuestionOptionInput[];
	multiSelect?: boolean;
}

export interface AnsweredQuestion {
	question: string;
	header: string;
	selectedLabels: string[];
	customText?: string;
	answer: string;
}

export interface QuestionsResult {
	cancelled: boolean;
	answers: AnsweredQuestion[];
}

const OTHER_LABEL = "その他（自由入力）";

interface QuestionState {
	checked: Set<number>;
	customText?: string;
}

export async function runQuestionsUI(ctx: ExtensionToolContext, questions: QuestionInput[]): Promise<QuestionsResult> {
	const hasMultipleQuestions = questions.length > 1;
	const totalTabs = hasMultipleQuestions ? questions.length + 1 : questions.length;
	const states: QuestionState[] = questions.map(() => ({ checked: new Set() }));

	function isAnswered(index: number): boolean {
		const state = states[index];
		return state.checked.size > 0 || !!state.customText;
	}

	function allAnswered(): boolean {
		return questions.every((_, i) => isAnswered(i));
	}

	function buildAnswer(index: number): AnsweredQuestion {
		const q = questions[index];
		const state = states[index];
		const selectedLabels = Array.from(state.checked)
			.sort((a, b) => a - b)
			.map((i) => q.options[i].label);
		const parts = [...selectedLabels];
		if (state.customText) parts.push(state.customText);
		return {
			question: q.question,
			header: q.header,
			selectedLabels,
			customText: state.customText,
			answer: parts.join(", "),
		};
	}

	return ctx.ui.custom<QuestionsResult>(
		(tui, theme, _keybindings, done) => {
			let currentTab = 0;
			let optionIndex = 0;
			let inputMode = false;
			let cachedLines: string[] | undefined;

			const editorTheme: EditorTheme = {
				borderColor: (s) => theme.fg("accent", s),
				selectList: {
					selectedPrefix: (t) => theme.fg("accent", t),
					selectedText: (t) => theme.fg("accent", t),
					description: (t) => theme.fg("muted", t),
					scrollInfo: (t) => theme.fg("dim", t),
					noMatch: (t) => theme.fg("warning", t),
				},
			};
			const editor = new Editor(tui, editorTheme);

			function refresh() {
				cachedLines = undefined;
				tui.requestRender();
			}

			function finish(cancelled: boolean) {
				if (cancelled) {
					done({ cancelled: true, answers: [] });
					return;
				}
				done({ cancelled: false, answers: questions.map((_, i) => buildAnswer(i)) });
			}

			function advanceTab() {
				optionIndex = 0;
				if (!hasMultipleQuestions) {
					finish(false);
					return;
				}
				currentTab = currentTab < questions.length - 1 ? currentTab + 1 : questions.length;
				refresh();
			}

			editor.onSubmit = (value) => {
				const trimmed = value.trim();
				const state = states[currentTab];
				if (!trimmed) {
					if (questions[currentTab].multiSelect) {
						state.customText = undefined;
					}
					inputMode = false;
					editor.setText("");
					refresh();
					return;
				}
				state.customText = trimmed;
				if (!questions[currentTab].multiSelect) {
					state.checked = new Set();
				}
				inputMode = false;
				editor.setText("");
				if (questions[currentTab].multiSelect) {
					refresh();
				} else {
					advanceTab();
				}
			};

			function handleInput(data: string) {
				if (inputMode) {
					if (matchesKey(data, Key.escape)) {
						inputMode = false;
						editor.setText("");
						refresh();
						return;
					}
					editor.handleInput(data);
					refresh();
					return;
				}

				if (hasMultipleQuestions) {
					if (matchesKey(data, Key.right) || matchesKey(data, Key.tab)) {
						currentTab = (currentTab + 1) % totalTabs;
						optionIndex = 0;
						refresh();
						return;
					}
					if (matchesKey(data, Key.left) || matchesKey(data, Key.shift("tab"))) {
						currentTab = (currentTab - 1 + totalTabs) % totalTabs;
						optionIndex = 0;
						refresh();
						return;
					}
				}

				if (hasMultipleQuestions && currentTab === questions.length) {
					if (matchesKey(data, Key.enter) && allAnswered()) {
						finish(false);
					} else if (matchesKey(data, Key.escape)) {
						finish(true);
					}
					return;
				}

				const q = questions[currentTab];
				const state = states[currentTab];
				const otherIndex = q.options.length;
				const optionCount = q.options.length + 1;

				if (matchesKey(data, Key.up)) {
					optionIndex = Math.max(0, optionIndex - 1);
					refresh();
					return;
				}
				if (matchesKey(data, Key.down)) {
					optionIndex = Math.min(optionCount - 1, optionIndex + 1);
					refresh();
					return;
				}

				if (q.multiSelect && matchesKey(data, Key.space)) {
					if (optionIndex === otherIndex) {
						if (state.customText) {
							state.customText = undefined;
						} else {
							inputMode = true;
							editor.setText("");
						}
					} else if (state.checked.has(optionIndex)) {
						state.checked.delete(optionIndex);
					} else {
						state.checked.add(optionIndex);
					}
					refresh();
					return;
				}

				if (matchesKey(data, Key.enter)) {
					if (optionIndex === otherIndex && (!q.multiSelect || !state.customText)) {
						inputMode = true;
						editor.setText(state.customText ?? "");
						refresh();
						return;
					}
					if (q.multiSelect) {
						if (isAnswered(currentTab)) advanceTab();
						return;
					}
					state.checked = new Set([optionIndex]);
					state.customText = undefined;
					advanceTab();
					return;
				}

				if (matchesKey(data, Key.escape)) {
					finish(true);
				}
			}

			function render(width: number): string[] {
				if (cachedLines) return cachedLines;
				const renderWidth = Math.max(1, width);
				const lines: string[] = [];

				function addWrapped(text: string) {
					lines.push(...wrapTextWithAnsi(text, renderWidth));
				}
				function addWrappedWithPrefix(prefix: string, text: string) {
					const prefixWidth = visibleWidth(prefix);
					if (prefixWidth >= renderWidth) {
						addWrapped(prefix + text);
						return;
					}
					const wrapped = wrapTextWithAnsi(text, renderWidth - prefixWidth);
					const continuationPrefix = " ".repeat(prefixWidth);
					for (let i = 0; i < wrapped.length; i++) {
						lines.push(`${i === 0 ? prefix : continuationPrefix}${wrapped[i]}`);
					}
				}

				lines.push(theme.fg("accent", "─".repeat(renderWidth)));

				if (hasMultipleQuestions) {
					const tabs: string[] = ["← "];
					for (let i = 0; i < questions.length; i++) {
						const isActive = i === currentTab;
						const answered = isAnswered(i);
						const box = answered ? "■" : "□";
						const color = answered ? "success" : "muted";
						const text = ` ${box} ${questions[i].header} `;
						const styled = isActive ? theme.bg("selectedBg", theme.fg("text", text)) : theme.fg(color, text);
						tabs.push(`${styled} `);
					}
					const canSubmit = allAnswered();
					const isSubmitTab = currentTab === questions.length;
					const submitText = " ✓ 送信 ";
					const submitStyled = isSubmitTab
						? theme.bg("selectedBg", theme.fg("text", submitText))
						: theme.fg(canSubmit ? "success" : "dim", submitText);
					tabs.push(`${submitStyled} →`);
					addWrappedWithPrefix(" ", tabs.join(""));
					lines.push("");
				}

				if (hasMultipleQuestions && currentTab === questions.length) {
					addWrappedWithPrefix(" ", theme.fg("accent", theme.bold("送信の確認")));
					lines.push("");
					for (let i = 0; i < questions.length; i++) {
						if (!isAnswered(i)) continue;
						const answer = buildAnswer(i);
						addWrappedWithPrefix(" ", `${theme.fg("muted", `${questions[i].header}: `)}${theme.fg("text", answer.answer)}`);
					}
					lines.push("");
					if (allAnswered()) {
						addWrappedWithPrefix(" ", theme.fg("success", "Enterで送信"));
					} else {
						const missing = questions
							.filter((_, i) => !isAnswered(i))
							.map((q) => q.header)
							.join(", ");
						addWrappedWithPrefix(" ", theme.fg("warning", `未回答: ${missing}`));
					}
				} else {
					const q = questions[currentTab];
					const state = states[currentTab];
					const hint = q.multiSelect ? ` ${theme.fg("muted", "（複数選択可）")}` : "";
					addWrappedWithPrefix(" ", theme.fg("text", q.question) + hint);
					lines.push("");

					for (let i = 0; i < q.options.length; i++) {
						const opt = q.options[i];
						const selected = i === optionIndex;
						const checked = state.checked.has(i);
						const prefix = selected ? theme.fg("accent", "> ") : "  ";
						const box = q.multiSelect ? `${checked ? "[x]" : "[ ]"} ` : "";
						const label = `${i + 1}. ${box}${opt.label}`;
						addWrappedWithPrefix(prefix, theme.fg(selected ? "accent" : "text", label));
						if (opt.description) {
							addWrappedWithPrefix("     ", theme.fg("muted", opt.description));
						}
					}

					const otherSelected = optionIndex === q.options.length;
					const otherChecked = !!state.customText;
					const otherBox = q.multiSelect ? `${otherChecked ? "[x]" : "[ ]"} ` : "";
					const otherLabel = `${q.options.length + 1}. ${otherBox}${OTHER_LABEL}${otherChecked ? ` (${state.customText})` : ""}`;
					addWrappedWithPrefix(otherSelected ? theme.fg("accent", "> ") : "  ", theme.fg(otherSelected ? "accent" : "text", otherLabel));

					if (inputMode) {
						lines.push("");
						addWrappedWithPrefix(" ", theme.fg("muted", "回答を入力:"));
						for (const line of editor.render(Math.max(1, renderWidth - 2))) {
							lines.push(` ${line}`);
						}
					}
				}

				lines.push("");
				if (hasMultipleQuestions && currentTab === questions.length) {
					addWrappedWithPrefix(" ", theme.fg("dim", "Tab/←→でタブ切替 • Enterで送信 • Escでキャンセル"));
				} else if (inputMode) {
					addWrappedWithPrefix(" ", theme.fg("dim", "Enterで確定 • Escで選択肢へ戻る"));
				} else {
					const q = questions[currentTab];
					const tabHelp = hasMultipleQuestions ? "Tab/←→でタブ切替 • " : "";
					const help = q.multiSelect
						? "↑↓で移動 • Spaceで選択切替 • Enterで確定 • Escでキャンセル"
						: "↑↓で移動 • Enterで選択 • Escでキャンセル";
					addWrappedWithPrefix(" ", theme.fg("dim", tabHelp + help));
				}
				lines.push(theme.fg("accent", "─".repeat(renderWidth)));

				cachedLines = lines;
				return lines;
			}

			return {
				render,
				invalidate: () => {
					cachedLines = undefined;
				},
				handleInput,
				get focused() {
					return editor.focused;
				},
				set focused(value: boolean) {
					editor.focused = value;
				},
			};
		},
		{ blocked: { kind: "question", message: questions[0].header } },
	);
}
