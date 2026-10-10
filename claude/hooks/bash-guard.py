#!/usr/bin/env python3
import json
import os
import re
import shlex
import sys
import time

NONE, ASK, DENY = 0, 1, 2
DECISION_NAME = {ASK: "ask", DENY: "deny"}
MAX_DEPTH = 5
MAX_NODES = 2000
TIME_BUDGET_SECONDS = 1.5

ASSIGNMENT = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)=")
TOOL_WORDS = re.compile(r"\b(gh|docker|git)\b", re.IGNORECASE)
TOOL_NAMES = {"git", "gh", "docker", "docker-compose"}
DYNAMIC_TOKEN = re.compile(r"[$`*?\[]")
TOOL_WITH_EXPANSION = re.compile(r"^(git|gh|docker)\W", re.IGNORECASE)
SHELLS = {"bash", "sh", "zsh", "dash", "ksh"}
SHELL_READERS = {"source", "."}
HEREDOC = re.compile(r"(?<!<)<<(?!<)(-?)\s*(['\"]?)([A-Za-z_][\w.-]*)\2")
HEREDOC_FEEDS_SHELL = re.compile(
    r"(^|[\s;&|(])((ba|z|da|k)?sh(\s+-\S+)*|(source|\.)\s+/dev/stdin)\s*$")

# tool名が単なる引数として現れるコマンド。ここでは尾部の判定も空白入り引数の再解析もしない
DATA_COMMANDS = set("""echo printf grep egrep fgrep rg ag which whereis type man
cat ls cd brew apt apt-get npm pnpm yarn pip pip3 open less head tail wc sed awk
diff cp mv rm mkdir touch chmod ln stat file tee code emacs vim nano""".split())

# ラッパー名 -> 値を取るオプション
WRAPPERS = {
    "env": {"-u", "--unset", "-C", "--chdir", "-S", "--split-string"},
    "command": set(),
    "time": set(),
    "nohup": set(),
    "exec": {"-a"},
    "builtin": set(),
    "sudo": {"-u", "--user", "-g", "--group", "-h", "--host", "-p", "--prompt",
             "-C", "-D", "--chdir", "-R", "--chroot", "-T", "-U", "-r", "-t"},
    "nice": {"-n", "--adjustment"},
}

GIT_VALUE_OPTIONS = {"-C", "-c", "--git-dir", "--work-tree", "--namespace",
                     "--exec-path", "--config-env"}
GIT_ASK_CONFIG_PREFIXES = ("alias.", "core.pager", "core.fsmonitor",
                           "core.sshcommand", "core.editor", "core.gitproxy",
                           "core.askpass")
GIT_HOOK_SKIPPING = {"commit", "merge", "rebase", "am"}
GIT_SHORT_VALUE_LETTERS = "mFCctuS"
GIT_LONG_VALUE_OPTIONS = {"--message", "--file", "--author", "--date",
                          "--template", "--reuse-message", "--reedit-message",
                          "--fixup", "--squash", "--cleanup"}
GIT_EXEC_OPTIONS = {"--exec", "-x", "--extcmd"}

DOCKER_VALUE_OPTIONS = {"-H", "--host", "--context", "-c", "--config", "-l",
                        "--log-level", "--tlscacert", "--tlscert", "--tlskey"}
DOCKER_READ_ONLY = set("""ps images info version logs inspect top stats events
port diff history search help""".split())
DOCKER_GROUPS = set("""image container network volume context system plugin
manifest node service stack secret config swarm""".split())
DOCKER_GROUP_READ_ONLY = {"ls", "list", "ps", "inspect", "history", "df"}
COMPOSE_VALUE_OPTIONS = {"-f", "--file", "-p", "--project-name", "--profile",
                         "--env-file", "--project-directory", "--ansi",
                         "--parallel", "--progress"}
COMPOSE_READ_ONLY = set("ps logs config ls top events images port version".split())

GH_VALUE_OPTIONS = {"-R", "--repo"}
GH_DENY_GROUPS = {"auth", "ssh-key", "gpg-key", "extension", "extensions"}
# 読み取り専用と確認できたものだけを許す。未知のサブコマンドは既定でask
GH_READ_ONLY = {
    "pr": {"view", "list", "diff", "checks", "status"},
    "issue": {"view", "list", "status"},
    "repo": {"view", "list"},
    "run": {"list", "view", "watch"},
    "release": {"list", "view"},
    "workflow": {"list", "view"},
    "cache": {"list"},
    "label": {"list"},
    "variable": {"list"},
    "secret": {"list"},
    "ruleset": {"list", "view", "check"},
    "codespace": {"list", "view"},
    "gist": {"list", "view"},
    "alias": {"list"},
    "config": {"get", "list"},
    "project": {"list", "view"},
    "org": {"list"},
}
GH_READ_ONLY_GROUPS = {"search", "status", "browse", "version", "help"}
GH_READ_ONLY_FLAGS = {"--version", "--help", "-h"}
GH_TOKEN_FLAGS = {"-t", "--show-token"}


class BudgetExceeded(Exception):
    pass


_state = {"nodes": 0, "deadline": 0.0}


def reset_budget():
    _state["nodes"] = 0
    _state["deadline"] = time.monotonic() + TIME_BUDGET_SECONDS


def tick():
    _state["nodes"] += 1
    if _state["nodes"] > MAX_NODES or time.monotonic() > _state["deadline"]:
        raise BudgetExceeded()


def strip_heredoc_bodies(text):
    # heredocの本文はコマンドではない。シェルに渡す場合だけ本文を残して判定対象にする
    out = []
    pos = 0
    while True:
        m = HEREDOC.search(text, pos)
        if not m:
            out.append(text[pos:])
            break
        nl = text.find("\n", m.end())
        if nl < 0:
            out.append(text[pos:])
            break
        line_start = text.rfind("\n", 0, m.start()) + 1
        feeds_shell = HEREDOC_FEEDS_SHELL.search(text[line_start:m.start()])
        word = m.group(3)
        i = nl + 1
        body_end = len(text)
        while i <= len(text):
            end = text.find("\n", i)
            line = text[i:] if end < 0 else text[i:end]
            if (line.lstrip("\t") if m.group(1) else line) == word:
                body_end = i
                break
            if end < 0:
                break
            i = end + 1
        if feeds_shell:
            out.append(text[pos:body_end])
        else:
            out.append(text[pos:nl + 1])
        pos = body_end
    return "".join(out)


def prepare(command):
    return strip_heredoc_bodies(command.replace("\\\n", ""))


def normalize_quotes_and_newlines(text):
    # shlexは改行を空白として扱うため、クォート外の改行だけ;に置き換えて区間を分ける。
    # $'..'・$".."はshlexが解釈できないので、クォート外の$を落として通常のクォートにする
    out = []
    quote = None
    escaped = False
    for i, ch in enumerate(text):
        if escaped:
            escaped = False
        elif ch == "\\" and quote != "'":
            escaped = True
        elif quote:
            if ch == quote:
                quote = None
        elif ch in "'\"":
            quote = ch
        elif ch == "\n":
            ch = ";"
        elif ch == "$" and text[i + 1:i + 2] in ("'", '"'):
            continue
        out.append(ch)
    return "".join(out)


def extract_substitutions(text):
    """最上位の$(...)・バッククォートの中身を1回の走査で取り出す。

    入れ子は取り出した中身を再帰で判定する側に任せる。閉じていないものがあれば
    (中身, True)の形で打ち切り、二次的な再走査をしない。
    """
    found = []
    n = len(text)
    quote = None
    i = 0
    while i < n:
        ch = text[i]
        if quote == "'":
            if ch == "'":
                quote = None
            i += 1
        elif ch == "\\":
            i += 2
        elif ch == "'" and quote is None:
            quote = "'"
            i += 1
        elif ch == '"':
            quote = None if quote == '"' else '"'
            i += 1
        elif ch == "`":
            j = i + 1
            while j < n and text[j] != "`":
                j += 2 if text[j] == "\\" else 1
            if j >= n:
                return found, True
            found.append(text[i + 1:j])
            i = j + 1
        elif ch == "$" and text.startswith("$(", i):
            depth = 0
            j = i + 1
            while j < n:
                c = text[j]
                if c == "\\":
                    j += 2
                    continue
                if c == "(":
                    depth += 1
                elif c == ")":
                    depth -= 1
                    if depth == 0:
                        break
                j += 1
            if j >= n:
                return found, True
            found.append(text[i + 2:j])
            i = j + 1
        else:
            i += 1
    return found, False


def is_separator(token):
    if not token or not set(token) <= set(";&|()<>"):
        return False
    if token[0] in "<>" and "(" not in token:
        return False
    return True


def tokenize_segments(text):
    lex = shlex.shlex(normalize_quotes_and_newlines(text), posix=True,
                      punctuation_chars=True)
    lex.whitespace_split = True
    segments = [[]]
    for token in lex:
        if is_separator(token):
            segments.append([])
        else:
            segments[-1].append(token)
    return [s for s in segments if s]


def base(token):
    return os.path.basename(token).lower()


def strip_wrappers(tokens):
    assignments = []
    i = 0
    while i < len(tokens):
        token = tokens[i]
        m = ASSIGNMENT.match(token)
        if m:
            assignments.append(m.group(1))
            i += 1
        elif base(token) in WRAPPERS:
            value_options = WRAPPERS[base(token)]
            i += 1
            while i < len(tokens) and tokens[i].startswith("-"):
                i += 2 if tokens[i] in value_options else 1
        else:
            break
    return assignments, tokens[i:]


def skip_global_options(args, value_options):
    i = 0
    while i < len(args) and args[i].startswith("-"):
        if args[i] in value_options:
            i += 1
        i += 1
    return args[:i], args[i:]


def worst(results):
    best = (NONE, "")
    for result in results:
        if result[0] > best[0]:
            best = result
    return best


def skips_hooks(args):
    # 短縮オプションは左から読み、値を取る文字(-m等)以降は値なので見ない
    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "--":
            return False
        if arg == "--no-verify":
            return True
        if arg in GIT_LONG_VALUE_OPTIONS:
            i += 1
        elif not arg.startswith("--") and arg.startswith("-") and len(arg) > 1:
            letters = arg[1:]
            for j, letter in enumerate(letters):
                if letter == "n":
                    return True
                if letter in GIT_SHORT_VALUE_LETTERS:
                    if j == len(letters) - 1 and letter != "u":
                        i += 1
                    break
        i += 1
    return False


def git_nested_commands(sub, sub_args):
    if sub in ("rebase", "difftool"):
        for i, arg in enumerate(sub_args):
            if arg in GIT_EXEC_OPTIONS and i + 1 < len(sub_args):
                yield sub_args[i + 1]
            elif arg.startswith(("--exec=", "--extcmd=")):
                yield arg.split("=", 1)[1]
    elif sub == "submodule" and "foreach" in sub_args:
        rest = sub_args[sub_args.index("foreach") + 1:]
        yield " ".join(a for a in rest if not a.startswith("-"))
    elif sub == "bisect" and sub_args[:1] == ["run"]:
        yield " ".join(sub_args[1:])


def first_positional(args):
    for arg in args:
        if not arg.startswith("-"):
            return arg.lower()
    return None


def judge_git(args, assignments, depth):
    options, rest = skip_global_options(args, GIT_VALUE_OPTIONS)
    results = []
    lowered = [o.lower() for o in options]
    if any("core.hookspath" in o for o in lowered):
        results.append((DENY, "core.hooksPathを上書きしてhookを飛ばさない"))
    if any(o.startswith(GIT_ASK_CONFIG_PREFIXES) for o in lowered):
        results.append((ASK, "gitの設定でコマンドを実行できるため確認が必要"))
    if any(a.upper().startswith("GIT_CONFIG") for a in assignments):
        results.append((ASK, "GIT_CONFIG*環境変数で設定を差し替えるため確認が必要"))
    if not rest:
        return worst(results)
    if DYNAMIC_TOKEN.search(rest[0]):
        results.append((ASK, "gitのサブコマンドが動的で判定できないため確認が必要"))
        return worst(results)
    sub = rest[0].lower()
    sub_args = rest[1:]
    nested_sub = first_positional(sub_args)
    if sub == "push" or (sub, nested_sub) in {("subtree", "push"),
                                              ("lfs", "push"),
                                              ("svn", "dcommit")} \
            or sub == "send-pack":
        results.append((DENY, "git pushは人間が行う"))
    if sub in GIT_HOOK_SKIPPING and skips_hooks(sub_args):
        results.append((DENY, "--no-verify（-n）でhookを飛ばさない"))
    if sub == "config" and any("core.hookspath" in a.lower() for a in sub_args):
        results.append((ASK, "core.hooksPathの変更は確認が必要"))
    for nested in git_nested_commands(sub, sub_args):
        results.append(judge(nested, depth + 1))
    return worst(results)


def judge_docker(args):
    _, rest = skip_global_options(args, DOCKER_VALUE_OPTIONS)
    if not rest:
        return NONE, ""
    sub = rest[0].lower()
    if sub == "compose":
        _, compose_rest = skip_global_options(rest[1:], COMPOSE_VALUE_OPTIONS)
        if not compose_rest or compose_rest[0].lower() in COMPOSE_READ_ONLY:
            return NONE, ""
        return ASK, "docker compose %sは読み取り専用と確認できないため確認が必要" % compose_rest[0]
    if sub in DOCKER_READ_ONLY:
        return NONE, ""
    if sub in DOCKER_GROUPS:
        nested = first_positional(rest[1:])
        if nested is None or nested in DOCKER_GROUP_READ_ONLY:
            return NONE, ""
        return ASK, "docker %s %sは確認が必要" % (sub, nested)
    return ASK, "docker %sは読み取り専用と確認できないため確認が必要" % rest[0]


def judge_gh(args):
    positional = []
    i = 0
    while i < len(args) and len(positional) < 2:
        arg = args[i]
        if arg in GH_READ_ONLY_FLAGS:
            return NONE, ""
        if arg in GH_VALUE_OPTIONS:
            i += 1
        elif not arg.startswith("-"):
            positional.append(arg.lower())
        i += 1
    if not positional:
        return NONE, ""
    group = positional[0]
    sub = positional[1] if len(positional) > 1 else None
    if group == "auth" and sub == "status" and not GH_TOKEN_FLAGS & set(args):
        return NONE, ""
    if group in GH_DENY_GROUPS:
        return DENY, "gh %sは認証情報・拡張を扱うため実行しない" % group
    if group in GH_READ_ONLY_GROUPS:
        return NONE, ""
    if sub in GH_READ_ONLY.get(group, ()):
        return NONE, ""
    return ASK, "gh %s %sは読み取り専用と確認できないため確認が必要" % (group, sub or "")


def shell_script(args):
    for i, arg in enumerate(args):
        if arg.startswith("--") or not arg.startswith("-"):
            continue
        if re.match(r"^-[A-Za-z]*c$", arg):
            return args[i + 1] if i + 1 < len(args) else None
        glued = re.match(r"^-[A-Za-z]*c(.+)$", arg)
        if glued:
            return glued.group(1)
    return None


def shell_fed_by_data(raw):
    if TOOL_WORDS.search(raw):
        return ASK, "シェルにデータを渡しておりgh・docker・gitを含むため確認が必要"
    return NONE, ""


def judge_shell(args, depth, raw):
    script = shell_script(args)
    if script is None:
        return shell_fed_by_data(raw)
    return judge(script, depth + 1)


def judge_generic(tokens, depth, raw):
    results = []
    for token in tokens:
        if TOOL_WITH_EXPANSION.match(token) and "$" in token:
            results.append((ASK, "gh・docker・gitの名前が動的で判定できないため確認が必要"))
    for token in tokens[1:]:
        if re.search(r"\s", token):
            results.append(judge(token, depth + 1))
    for k in range(1, len(tokens)):
        if base(tokens[k]) in TOOL_NAMES:
            results.append(judge_segment(tokens[k:], depth, raw))
            break
    return worst(results)


def judge_segment(tokens, depth, raw):
    tick()
    assignments, tokens = strip_wrappers(tokens)
    if not tokens:
        return NONE, ""
    if len(tokens[0]) > 1 and tokens[0].startswith("{"):
        tokens = ["{", tokens[0][1:]] + tokens[1:]
    head = tokens[0]
    name = base(head)
    args = tokens[1:]
    if head[0] in "$`":
        return ASK, "コマンド名が動的で判定できないため確認が必要"
    if TOOL_WITH_EXPANSION.match(head) and "$" in head:
        return ASK, "gh・docker・gitの名前が動的で判定できないため確認が必要"
    if name == "git":
        return judge_git(args, assignments, depth)
    if name == "docker":
        return judge_docker(args)
    if name == "docker-compose":
        return ASK, "docker-composeは確認が必要"
    if name == "gh":
        return judge_gh(args)
    if name in SHELLS:
        return judge_shell(args, depth, raw)
    if name in SHELL_READERS:
        return shell_fed_by_data(raw)
    if name == "eval":
        return judge(" ".join(args), depth + 1)
    if name in DATA_COMMANDS:
        return NONE, ""
    return judge_generic(tokens, depth, raw)


def unparsable(command):
    if TOOL_WORDS.search(command):
        return ASK, "コマンドを解析できず、gh・docker・gitを含むため確認が必要"
    return NONE, ""


def judge(command, depth=0):
    tick()
    if depth > MAX_DEPTH:
        return unparsable(command)
    text = prepare(command)
    try:
        segments = tokenize_segments(text)
    except ValueError:
        return unparsable(command)
    results = [judge_segment(s, depth, text) for s in segments]
    inners, unclosed = extract_substitutions(text)
    results += [judge(inner, depth + 1) for inner in inners]
    if unclosed and TOOL_WORDS.search(text):
        results.append((ASK, "コマンド置換が閉じておらず、gh・docker・gitを含むため確認が必要"))
    return worst(results)


def decide(data):
    if not isinstance(data, dict) or data.get("tool_name") != "Bash":
        return NONE, ""
    tool_input = data.get("tool_input")
    command = tool_input.get("command") if isinstance(tool_input, dict) else None
    if not isinstance(command, str):
        return NONE, ""
    reset_budget()
    try:
        return judge(command)
    except BudgetExceeded:
        return unparsable(command)


def main():
    # 締める専用のフックなので、失敗時にClaude Code本体を止めるより意見なしで終える方を選ぶ
    try:
        level, reason = decide(json.load(sys.stdin))
        if level:
            print(json.dumps({"hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": DECISION_NAME[level],
                "permissionDecisionReason": reason,
            }}, ensure_ascii=False))
    except Exception:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
