# Rules for creating/updating the plan files

This file defines how to manage the plan files: `path/to/plan-1-todo-steps.md`, `path/to/plan-2-current-step.md`, and `path/to/plan-3-done-steps.md`.

- `plan-1-todo-steps.md` lists upcoming steps, ordered top to bottom. The topmost item is the next step to activate.

- `plan-2-current-step.md` holds the single step in progress, marked `status: current`. It is created only when implementation begins by moving the topmost todo step into it (typically triggered by "do next step" or an explicit request to continue work). It represents what has just been worked on in the latest turn and what is currently being worked on by the AI; it is not a queue of upcoming steps. If work spans multiple turns, add sub-steps here.

- `plan-3-done-steps.md` archives completed steps, marked `status: done`, with a concise summary.

Current is created when implementation starts and exists only to reflect the work that is actively being performed by the AI, including what has just been implemented. Do not treat the current step as the "next to do"; it mirrors the work just performed and the ongoing work until the user says "do next step" or "continue to work on current step". Do not create or keep a current step during planning-only phases.

Unless specified otherwise, these files live in the same directory as this `_plan-rules.md` file.

Some rules on the markdown formatting: 

- Use `-` character for bullet points. 
- When the bullet points have long line or sub bullet points, have a empty line between the top level bullet points 
- For headings, except for the `## Step` and `## Sub Step`, leave exactly one empty line after the heading
    - For `## Step` and `## Sub Step`, do not insert any empty line after the heading. The `status: ...` line must be immediately after the heading with no blank line in between, followed by any `time-...` fields on subsequent lines. 

## Core flow

- When asked to create or update the plan, do not implement any step. Only create or modify the plan files. Implementation work begins only when the user explicitly requests "do next step" or "continue to work on current step".

- Always move a step from todo to current before doing any work on it. Never move a todo step directly to done.

- Create `plan-2-current-step.md` only when beginning implementation. When beginning work, move the topmost step from `plan-1-todo-steps.md` into it and set `status: current`.

- When the user says "do next step":
  - If a current step exists, finalize it, move it to done with `status: done`, then activate the next topmost todo as the new current.
  - If there is no current step, activate the topmost todo as current and proceed.

- When a step becomes current, keep its original todo content verbatim. Only add supplementary sections like `### Implementation Considerations` or sub-steps as needed.

- While continuing work on the current step, append sub-steps and notes to the same section. Do not create another top-level step.

## plan-1-todo-steps.md rules

- Creating or updating the plan is planning-only. Do not begin implementing any step while composing or editing the plan files.
- Each step uses a heading `## Step - short title for the work`.

- Include `status: not_started`.

- If available, add `time-created: ...` using local time in RFC 3339 (second precision), for example `2025-10-26T09:52:21-07:00`.

- After an empty line, provide a concise, complete description of the step.

- When a step is activated, move the entire step to `plan-2-current-step.md`, change `status` to `current`, and remove it from todo. Preserve all original content.

## plan-2-current-step.md rules

- Contains exactly one step with `status: current` only while implementation is in progress. If there is no active implementation, this file may be absent or empty. Create it and activate the topmost todo only when beginning implementation.

- Copy the full body from todo when the step becomes current; do not delete details. Add follow-up sections as needed without altering the original text.

- Keep the same heading format `## Step - short title for the work`.

- Preserve the original `time-created: ...`. Add new timestamps only when relevant, using RFC 3339 (second precision).

- Use the body to track sub-steps, design notes, decisions, and outstanding questions in chronological order.

- Sub-steps format:
  - `### sub-step - SUB_STEP_SHORT_DESCRIPTION`
  - Under it, use `#### Implementation Considerations` (and other fourth-level headings as needed).

- When the user requests to move on:
  - If there are no sub-steps, move the step as-is to done with `status: done`.
  - If there are many sub-steps or back-and-forth, consolidate them into a concise set of instructions or summary, then mark `status: done` and archive.

- After archiving the current step, immediately activate the next topmost todo as the new current to continue the flow.

## plan-3-done-steps.md rules

- Only steps that have been in `plan-2-current-step.md` as `status: current` can be moved here.

- Use the same heading format as the other files.

- Set `status: done`. Keep the original `time-created: ...`, and add `time-done: ...` when finalized.

- If there were no additional sub-steps while current, carry the content over verbatim so nothing is lost.

- Provide a consolidated summary capturing key details, decisions, and answers without the iterative back-and-forth.

- List steps from oldest to newest, newest at the bottom.

## For each implementation of a step or sub-step

When you implement or update a current step (including sub-steps), suggest a git commit command using the following format:

- Prefix the message with a symbol: `.` minor, `-` fix, `+` addition, `^` improvement, `!` change, `>` refactor.

- Format: `<symbol> <module/topic> - <short description>`.

- If new files were created, prepend `git add -A .`.

(Put this in at the top of your response. )

Example:

<suggested_git_command>
git commit -a -m ". chat_response - Fix doc typos and provider_model_iden doc"
</suggested_git_command>



