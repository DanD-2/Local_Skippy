# Standalone Repository Checklist

## Purpose

Use this checklist when promoting `Local_LLM` into its own top-level git repository.

The goal is to move only the files this project actually needs and avoid hidden coupling to the surrounding Series3 tree.

## Repository Notice

This project is private and internal-use only.

Before copying or moving it into another repository location, keep `LICENSE.md` with the project and do not treat the resulting repository as open source.

## Minimum Required Files

Move these items into the new repository root:

1. `README.md`
2. `.gitignore`
3. `LICENSE.md`
4. `CONTRIBUTING.md`
5. `docs/`
6. `src/`

That is the minimum project set needed to preserve the current planning docs, runbooks, and helper artifacts.

## Extraction Steps

1. Copy the entire `Local_LLM` directory to the new repository location.
2. Confirm the new repository root contains `README.md`, `.gitignore`, `LICENSE.md`, `CONTRIBUTING.md`, `docs/`, and `src/`.
3. Run a quick text search for old parent-repo path assumptions such as `Series3/`.
4. Initialize git in the new root if the destination is not already a repository.
5. Commit the baseline import before making environment-specific edits.

## Suggested Bootstrap Commands

From the new repository root:

```powershell
git init
git add .
git commit -m "Initial Local_LLM import"
```

## First Validation Checks

After extraction, confirm these still hold:

1. `README.md` reads correctly as a top-level project entry point.
2. `docs/z8g4-install-commands.md` assumes the repository root, not a parent workspace root.
3. `src/README.md` still matches the files present under `src/`.
4. No document assumes another project is required for first deployment.

## Optional Follow-Up

Add these only if the new repository needs them:

1. CI validation for shell syntax checks.
2. Issue templates or contribution guidance.
3. A secrets-handling note for local operator overrides.
4. A separate backup and monitoring runbook if operations will be handed to another person.