# Contributing

## Purpose

Use this guide for small, focused changes to the Local Skippy repository.

## Working Rules

1. Keep changes scoped to the Local Skippy AI appliance — no workstation or creative-tool content.
2. Do not introduce dependencies on external repositories unless they are clearly optional.
3. Prefer updating existing runbooks and helper scripts over adding duplicate files.
4. Keep secrets, passwords, tokens, API keys, and private host data out of committed files.
5. Treat DNS, reverse proxy, monitoring, and backup integrations as optional layers.
6. The Evaluator agent may propose changes but must never be configured to auto-enact them.

## Change Process

1. Start from the Local Skippy repository root.
2. Make the smallest change that solves the target problem.
3. Update documentation when behavior, assumptions, or operator steps change.
4. Validate changed shell scripts with `bash -n` when applicable.
5. Validate changed markdown or service files with the available editor checks when possible.

## Pull Request Expectations

1. State the problem being solved.
2. Summarize the operational impact.
3. List the validation performed.
4. Call out any remaining host-specific assumptions, such as GPU numbering or mount identifiers.

## Security Notes

1. Do not commit plaintext credentials, API keys, or tokens.
2. Keep the deployment LAN-only unless a change explicitly and intentionally expands exposure.
3. Proxmox integration must use a restricted API token — never admin credentials.
4. Agent automation boundaries must be preserved: the Evaluator proposes, operators decide.

## Archive Policy

Legacy workstation and creative-tool documentation is in `archive/`. Do not move archive content back into `docs/`.