import importlib.util
import json
import os
import subprocess
import sys
import time
import unittest

HOOK_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "bash-guard.py")

# ファイル名にハイフンがあり通常のimportができないためパスで読み込む
_spec = importlib.util.spec_from_file_location("bash_guard", HOOK_PATH)
bash_guard = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(bash_guard)


def run_hook(stdin_text):
    proc = subprocess.run(
        [sys.executable, HOOK_PATH],
        input=stdin_text,
        capture_output=True,
        text=True,
    )
    return proc.returncode, proc.stdout


def bash_payload(command):
    return json.dumps({"tool_name": "Bash", "tool_input": {"command": command}})


def verdict(command):
    """フック全体を通した判定。'deny' / 'ask' / None を返す。"""
    code, out = run_hook(bash_payload(command))
    assert code == 0, "exit code %s" % code
    if not out.strip():
        return None
    data = json.loads(out)["hookSpecificOutput"]
    assert data["hookEventName"] == "PreToolUse"
    assert data["permissionDecisionReason"]
    return data["permissionDecision"]


class EndToEndTest(unittest.TestCase):
    def test_git_push_is_denied(self):
        self.assertEqual(verdict("git push"), "deny")

    def test_neutral_commands_have_no_opinion(self):
        for cmd in ["git status", "git commit -m x", "git log --grep push",
                    "ls", "", "docker ps", "docker compose ps",
                    "docker -H tcp://x ps", "gh pr view 1",
                    "gh pr list --json number"]:
            with self.subTest(cmd=cmd):
                self.assertIsNone(verdict(cmd))

    def test_non_bash_tool_has_no_opinion(self):
        payload = json.dumps({"tool_name": "Read",
                              "tool_input": {"command": "git push"}})
        self.assertEqual(run_hook(payload), (0, ""))


class RobustnessTest(unittest.TestCase):
    def assert_silent(self, stdin_text):
        self.assertEqual(run_hook(stdin_text), (0, ""))

    def test_empty_stdin(self):
        self.assert_silent("")

    def test_invalid_json(self):
        self.assert_silent("{not json")

    def test_missing_tool_input(self):
        self.assert_silent(json.dumps({"tool_name": "Bash"}))

    def test_non_dict_json(self):
        self.assert_silent("[1, 2]")

    def test_non_string_command(self):
        self.assert_silent(json.dumps(
            {"tool_name": "Bash", "tool_input": {"command": 5}}))


class VerdictCase(unittest.TestCase):
    def assert_verdicts(self, expected, commands):
        for cmd in commands:
            with self.subTest(cmd=cmd):
                self.assertEqual(verdict(cmd), expected)


class GitTest(VerdictCase):
    def test_push_with_global_options_and_wrappers_is_denied(self):
        self.assert_verdicts("deny", [
            "git -C . push",
            "git -c x=y push origin main",
            "git --git-dir=.git push",
            "git --git-dir .git push",
            "git --no-pager push",
            "/usr/bin/git push",
            "FOO=1 git push",
            "env git push",
            "env -u HOME git push",
            "sudo -u me git push",
            "command git push",
            "time nohup git push",
        ])

    def test_push_in_nested_or_compound_commands_is_denied(self):
        self.assert_verdicts("deny", [
            "bash -c 'git push'",
            "sh -c \"git push\"",
            "zsh -c 'ls; git push'",
            "bash -lc 'git push'",
            "echo $(git push)",
            "echo \"$(git push)\"",
            "echo `git push`",
            "ls && git push",
            "ls | git push",
            "ls\ngit push",
            "(git push)",
            "bash -c \"bash -c 'git push'\"",
        ])

    def test_quoted_push_text_is_not_a_command(self):
        self.assert_verdicts(None, [
            "echo 'git push'",
            "git commit -m 'git push later'",
            "echo a\\ git push",
        ])

    def test_commit_that_skips_hooks_is_denied(self):
        self.assert_verdicts("deny", [
            "git commit --no-verify",
            "git commit -m x --no-verify",
            "git commit -nm x",
            "git commit -n -m x",
            "git -c core.hooksPath=/dev/null commit -m x",
            "git -c core.hookspath=/dev/null push",
        ])

    def test_ordinary_commit_and_read_only_commands_pass(self):
        self.assert_verdicts(None, [
            "git commit -am x",
            "git commit --amend --no-edit",
            "git -C sub status",
            "git -c user.name=x log",
            "git diff --name-only",
        ])


class DockerTest(VerdictCase):
    def test_mutating_subcommands_ask_even_after_global_options(self):
        self.assert_verdicts("ask", [
            "docker run x",
            "docker -H tcp://x run x",
            "docker --host=tcp://x run x",
            "docker --context c exec x",
            "docker -l debug rm x",
            "docker compose -f x.yml up",
            "docker compose --profile p run x",
            "docker compose -p n down",
            "docker --context c compose --env-file e up -d",
            "docker-compose up",
            "docker-compose ps",
            "sudo docker run x",
        ])

    def test_read_only_subcommands_pass(self):
        self.assert_verdicts(None, [
            "docker ps",
            "docker images",
            "docker logs x",
            "docker inspect x",
            "docker version",
            "docker compose ps",
            "docker compose -f x.yml logs",
            "docker -H tcp://x ps",
            "docker",
        ])


class GhTest(VerdictCase):
    def test_credential_and_extension_groups_are_denied(self):
        self.assert_verdicts("deny", [
            "gh auth token",
            "gh ssh-key add",
            "gh gpg-key list",
            "gh extension install x",
            "gh extensions list",
            "gh -R o/r auth token",
        ])

    def test_unlisted_subcommands_ask_by_default(self):
        self.assert_verdicts("ask", [
            "gh pr create",
            "gh pr merge 1",
            "gh release delete v1",
            "gh repo edit",
            "gh new-subcommand-xyz",
            "gh api repos/x",
            "gh -R o/r pr create",
            "gh pr -R o/r comment 1",
        ])

    def test_read_only_subcommands_pass(self):
        self.assert_verdicts(None, [
            "gh pr view 1",
            "gh pr list --json number",
            "gh -R o/r pr diff 1",
            "gh pr checks",
            "gh issue list",
            "gh repo view",
            "gh run view 1",
            "gh release list",
            "gh workflow view x",
            "gh search prs foo",
            "gh status",
            "gh browse",
            "gh --version",
            "gh help",
            "gh cache list",
            "gh ruleset check",
            "gh codespace view",
            "gh",
        ])


class SegmentTest(VerdictCase):
    def test_strictest_segment_wins(self):
        self.assert_verdicts("ask", ["git status && docker run x"])
        self.assert_verdicts("deny", [
            "git push; docker run x",
            "docker run x; git push",
        ])

    def test_unparsable_command_asks_only_when_a_tool_word_appears(self):
        self.assert_verdicts("ask", ['gh "pr', "echo 'unterminated; git"])
        self.assert_verdicts(None, ['echo "unterminated', "echo 'x"])

    def test_redirects_are_not_separators(self):
        self.assert_verdicts(None, ["git status 2>&1", "docker ps > out.txt"])
        self.assert_verdicts("deny", ["git push 2>&1"])


class LineContinuationAndCaseTest(VerdictCase):
    def test_backslash_newline_is_joined(self):
        self.assert_verdicts("deny", [
            "git \\\npush",
            "echo hi; \\\ngit push",
        ])

    def test_tool_names_are_case_insensitive(self):
        self.assert_verdicts("deny", ["GIT push"])
        self.assert_verdicts("ask", ["DOCKER run x", "DOCKER compose up"])


class CompoundSyntaxTest(VerdictCase):
    def test_push_behind_shell_syntax_is_denied(self):
        self.assert_verdicts("deny", [
            "> /dev/null git push",
            "! git push",
            "{ git push; }",
            "{git push;}",
            "true && { git push; }",
            "time { git push; }",
            "if true; then git push; fi",
            "for i in 1; do git push; done",
            "while true; do git push; done",
            "trap 'git push' EXIT",
            "f() { git push; }; f",
            "coproc git push",
        ])


class EvalTest(VerdictCase):
    def test_eval_is_judged_recursively(self):
        self.assert_verdicts("deny", [
            'eval "git push"',
            "eval git push",
            "sh -c 'eval git push'",
        ])
        self.assert_verdicts("ask", ["eval 'docker run x'"])


class ExecutorWrapperTest(VerdictCase):
    def test_tool_after_unknown_wrapper_is_judged(self):
        self.assert_verdicts("deny", [
            "timeout 5 git push",
            "xargs git push",
            "xargs -I{} git push {}",
            "find . -exec git push \\;",
            "watch git push",
            "stdbuf -o0 git push",
            "setsid git push",
            "flock x git push",
            "parallel git push ::: a",
            "ssh host git push",
            "ssh host 'git push'",
            "su -c 'git push'",
            "doas git push",
            "nix develop -c git push",
            "direnv exec . git push",
        ])
        self.assert_verdicts("ask", [
            "timeout 5 docker run x",
            "xargs docker rm",
            "xargs gh pr create",
        ])


class ShellOptionTest(VerdictCase):
    def test_shell_script_is_found_after_other_options(self):
        self.assert_verdicts("deny", [
            "bash --norc -c 'git push'",
            "bash -o errexit -c 'git push'",
            "bash -O extglob -c 'git push'",
            "bash --login -c 'git push'",
            "bash --rcfile x -c 'git push'",
            'bash -c"git push"',
            "bash -c $'git push'",
        ])


class ShellFedByDataTest(VerdictCase):
    def test_shell_reading_stdin_asks_when_a_tool_word_appears(self):
        self.assert_verdicts("ask", [
            'echo "git push" | sh',
            "printf 'git push' | bash",
            'bash <<< "git push"',
            "bash <(echo git push)",
            "source <(echo git push)",
            ". /dev/stdin <<< 'git push'",
        ])

    def test_shell_reading_stdin_without_tool_word_passes(self):
        self.assert_verdicts(None, ["echo hi | sh", "bash ./setup.sh"])

    def test_heredoc_body_for_a_shell_is_judged(self):
        self.assert_verdicts("deny", ["bash <<'EOF'\ngit push\nEOF"])

    def test_heredoc_body_for_data_commands_is_not_judged(self):
        self.assert_verdicts(None, [
            "cat > f <<'EOF'\ngit push origin\nEOF",
            "cat <<-EOF\n\tgit push\n\tEOF",
            'git commit -m "$(cat <<\'EOF\'\nmsg with git push\nEOF\n)"',
        ])


class DynamicWordTest(VerdictCase):
    def test_dynamic_command_or_subcommand_asks(self):
        self.assert_verdicts("ask", [
            "g=git; $g push",
            "x=push; git $x",
            "git ${x:-push}",
            "$(echo git) push",
            "${GIT:-git} push",
            "git${IFS}push",
            '"$(echo docker)" run x',
            "`echo git` push",
            "git pu*",
        ])

    def test_ansi_c_quoted_subcommand_is_not_hidden(self):
        # $'push'はクォートを外して解釈するのでaskでなくdenyになってもよい
        self.assertIn(verdict("git $'push'"), ("ask", "deny"))


class GitExtraTest(VerdictCase):
    def test_other_pushing_subcommands_are_denied(self):
        self.assert_verdicts("deny", [
            "git subtree push --prefix=x origin main",
            "git lfs push x",
            "git svn dcommit",
            "git send-pack x",
        ])

    def test_hooks_are_not_skipped_by_other_subcommands(self):
        self.assert_verdicts("deny", [
            "git -c core.hooksPath=/dev/null merge x",
            "git -c core.hooksPath=/dev/null status",
            "git merge --no-verify x",
            "git rebase --no-verify x",
            "git am --no-verify x",
            "git commit -an",
        ])

    def test_config_that_can_run_commands_asks(self):
        self.assert_verdicts("ask", [
            "git -c alias.p=push p",
            "git -c 'alias.p=!git push' p",
            "git -c core.pager='git push' log",
            "git -c core.fsmonitor=x status",
            "git -c core.sshCommand=x fetch",
            "git -c core.editor=x commit",
            "GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath "
            "GIT_CONFIG_VALUE_0=/dev/null git commit -m x",
            "git config core.hooksPath /dev/null && git commit -m x",
        ])

    def test_subcommands_that_run_commands_are_judged(self):
        self.assert_verdicts("deny", [
            "git submodule foreach 'git push'",
            "git rebase --exec 'git push' main",
            "git rebase -x 'git push' main",
            "git bisect run git push",
            "git difftool -x 'git push'",
        ])

    def test_value_taking_short_options_do_not_trigger_no_verify(self):
        self.assert_verdicts(None, [
            "git commit -mnew",
            'git commit -m"clean"',
            'git commit -am"clean"',
            "git commit -uno",
            "git commit -m -n",
            "git commit -m '-n'",
            "git commit -F -n",
            'git commit -m "no -n here"',
            "git commit -- -n",
            "git log --grep=push",
            "git stash push",
        ])


class DockerAllowlistTest(VerdictCase):
    def test_unlisted_subcommands_ask(self):
        self.assert_verdicts("ask", [
            "docker debug x",
            "docker rename a b",
            "docker pause a",
            "docker attach a",
            "docker compose scale web=2",
            "docker network create x",
            "docker system prune",
            "docker image rm x",
        ])

    def test_read_only_group_subcommands_pass(self):
        self.assert_verdicts(None, [
            "docker image ls",
            "docker container ls",
            "docker network inspect x",
            "docker system df",
            "docker top x",
            "docker compose -f x.yml ps",
            "docker compose config",
        ])


class GhExtraTest(VerdictCase):
    def test_auth_status_passes_but_token_display_is_denied(self):
        self.assert_verdicts(None, ["gh auth status"])
        self.assert_verdicts("deny", [
            "gh auth status --show-token",
            "gh auth status -t",
            "gh auth token",
            "gh -R o/r auth token",
        ])

    def test_more_read_only_subcommands_pass(self):
        self.assert_verdicts(None, [
            "gh gist list",
            "gh gist view x",
            "gh alias list",
            "gh config get x",
            "gh project list",
            "gh org list",
            "gh run watch 1",
            "gh -R x/y pr view 1",
        ])


class DataCommandTest(VerdictCase):
    def test_tool_names_as_plain_arguments_have_no_opinion(self):
        self.assert_verdicts(None, [
            "brew install git",
            "which docker",
            "grep -n push file",
            "echo git push",
            "echo '$(git push)'",
            "man git",
            "npm install docker",
            "python3 script.py git",
        ])


class PerformanceTest(unittest.TestCase):
    def timed_verdict(self, command):
        start = time.monotonic()
        result = verdict(command)
        self.assertLess(time.monotonic() - start, 3)
        return result

    def test_many_unclosed_substitutions_ask(self):
        self.assertEqual(self.timed_verdict("$(echo git " * 60), "ask")

    def test_deeply_nested_substitutions_finish_quickly(self):
        command = "$(echo " * 30 + "git push" + ")" * 30
        self.assertIn(self.timed_verdict(command), ("ask", "deny"))

    def test_long_command_with_many_substitutions_finishes_quickly(self):
        command = "echo " + " ".join("$(echo %d)" % i for i in range(300))
        self.timed_verdict(command)


if __name__ == "__main__":
    unittest.main()
