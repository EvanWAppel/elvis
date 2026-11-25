# elvis — agent notes

The portfolio-wide rules in `~/Documents/portfolio/CLAUDE.md` apply here.

<!-- factotum:blocked-protocol -->
**Blockers → Jira (fleet repo, system standard).** Anything only Evan can resolve — a credential, a deploy, external access, or a decision — becomes a ticket in the Jira `EA` space on *Needs Evan*, component `elvis`, **with the specific steps a human takes to unblock it** (the action, where, any URL / path / env-var). From a session on Evan's Mac, file it with `uv run --project ~/Documents/_system sys file-blocker --component elvis --title "…" --body-file steps.md` (add `--nice-to-have` for 🟡; default 🔴); fleet daemon runs on the box park their own ticket on *Needs Evan* instead. Two kinds stay in the root `BLOCKED.md`, in the standard format: **`[sec]` blockers** (`- [ ] 🔴 [sec] …`, because the security dashboard counts them only there, D-052) and anything Jira must not hold — roster/user data, secret values, unpublished writing (D-039). `BLOCKED.md` keeps its heading and a pointer to Jira. _system's blocked-router mirrors both into Evan's todo dashboard. Full rule: Evan's global `~/.claude/CLAUDE.md` and _system D-051/D-052.
<!-- /factotum:blocked-protocol -->

**Closing blockers fixed in a session (_system D-055/D-056/D-056a).** When work in a session resolves something a *Needs Evan* ticket is waiting on, propose closing it — never close silently:
1. **Find it.** Search `project = EA AND component = elvis AND status = "Needs Evan"` (Atlassian connector). Name the match and why; if it's ambiguous, ask.
2. **Draft the comment** in a scratchpad file: what was done, how it was verified (or "on Evan's word" when only he can check, e.g. a value in an env file), and the commit/PR link. Never a secret value.
3. **Dry-run, then ask.** `uv run --project ~/Documents/_system sys resolve-blocker EA-N --comment-file note.md --dry-run`, then ask with AskUserQuestion, comment in the preview: *Close it* / *Edit the comment* / *Comment only, leave open* / *Skip*. Several tickets → one question.
4. **Only on "Close it"**, run it without `--dry-run`; report the new status and link. *Comment only* (a partial fix) posts via the connector and leaves the ticket on *Needs Evan*.
- A refusal is an answer, not an obstacle. A merge-handoff refusal means: ask whether the PR is merged, and add `--done` only after Evan says yes. Don't reassign a ticket to get past the bot-assignee check without asking.
- `[sec]` and other `BLOCKED.md` items aren't in Jira: tick the line there instead.
- If `sys resolve-blocker` doesn't exist, the local `_system` checkout is behind its `main`. Say so and stop; don't switch its branch.
