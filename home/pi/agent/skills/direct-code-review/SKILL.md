---
name: direct-code-review
description: Review the current worktree or merge request directly with the agent's own reasoning. Use when the user asks for a code review, asks to review current changes, or wants obvious bugs fixed while decisions are collected for review. Do not use Plannotator or any browser review UI unless the user explicitly requests it.
---

# Direct Code Review

Review code directly in the current repository. The default objective is to find real regressions or inconsistencies, fix only changes that are clearly correct, and collect decisions that require user judgment.

## Workflow

1. Establish the review scope:
   - Inspect `git status`.
   - Inspect staged, unstaged, and untracked changes as relevant.
   - Identify the appropriate base branch or merge-base before reviewing a merge request or branch diff.
2. Read the diff and trace affected call paths, types, tests, configuration, and neighboring code. Do not judge a line in isolation.
3. Prioritize concrete issues:
   - correctness and regressions
   - unsafe state/data handling, error handling, concurrency, and security problems
   - API or schema compatibility
   - missing or invalid tests
   - deviations from established local conventions that can cause maintenance or runtime problems
4. For an obvious, low-risk fix that needs no product or architectural decision:
   - make the edit directly;
   - run the narrowest relevant validation available; and
   - re-check the modified diff.
5. Do not make speculative refactors, style-only churn, or behavior/product changes just to improve the diff.
6. If resolving an issue requires a decision, external information, or changes beyond the safe review scope, leave the code unchanged and add it to the decision list.

## Reporting

Report in this order:

1. **Fixed directly** — file paths, what changed, and validation run.
2. **Decision needed** — only unresolved items; explain the risk, relevant file paths, and the concrete decision required.
3. **Review result** — state clearly when no remaining actionable findings exist.

Findings must cite a file path and line number whenever possible. Do not invent issues merely to produce review feedback.

## Plannotator Boundary

Never launch `/plannotator-review`, `plannotator review`, or a browser-based review workflow for an ordinary code-review request. Use those only when the user explicitly asks for Plannotator or its browser UI.
