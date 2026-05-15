# Rules & Skill for creating and following a dev plan

## When to use this skill

Use this file when the user need to create, follow, implement the development plan.

## Key Rules

This file defines how to manage the plan file. The plan flow now uses a single `plan.md` file with a flat sequence of step sections.

- `plan.md` **must always live in the same directory as this `_plan-rules.md` file**.

- Create, read, and modify `plan.md` in the same directory as the `_plan-rules.md` file. Never place it in any other directory.

- `plan.md` contains the full plan state in one place as a flat list of `## ... Step - ...` sections, where each heading emoji communicates the step state.

Important note:

- Make sure when asked to implement (e.g., do, work, ...) the next step or to work/fix active step, the plan file only gets updated if work has been done, or if a note needs to be added in the active step. Do not update the plan file if you did not do any implementation.

- If you cannot do the next step because there is not enough information, just tell the user using the `<missing_files>` tag or in the response, but do not update the plan file, except if asked by the user to say why implementation was not done for example.

- Only move a todo step to active when implementation is actually performed in that same response.

- Keep the active step as a real in-progress implementation mirror, not a planning transition artifact.

- The current not-started step exists only to reflect the next step that is ready to be implemented.
Do not treat every future step as active. Keep only the current next step as the leading `## ■ Step - ...` entry, and convert it only when implementation has been performed in that same response.

- When the user asks a question about the current step being implemented, add this information to that step section in `plan.md`.

- Only update a step toward done if it can actually be implemented. If the next step cannot be implemented, due to missing files or anything else, then just tell the user in the prompt or note it as missing files, but do not edit the plan file.

- When the user asks to do, that is, implement, the next step, but there is no remaining not-started step and there is a current step that was being worked on, simply mark that current step done as usual, and inform the user that everything is complete.

- If the user continues to ask to do something when there is no remaining `## ■ Step - ...`, just say that there are no more items in `plan.md`.

- When the user says there is a bug in the current step, fix the bug and update that step with the sub-step as defined below. The same applies if the user says it wants to add something new to the current step. Just a sub-step, as defined below.

## Markdown formatting rules

- Favor bullet point format for the step content when appropriate.
- Use `-` character for bullet points
- When bullet points have a long line or sub-bullet points, include an empty line between the top-level bullet points
- For headings, except for the `## ... Step` and `### sub-step`, leave exactly one empty line after the heading.
  - For `## ■ Step ...`, `## ✅ Step ...`, `## ✔ Step ...`, and `### sub-step ...`, do not insert any empty line after the heading. The `      status: ...` line must be immediately after the heading with no blank line in between, followed by any `time-...` fields on subsequent lines.

- Info alignment: It is important that the values of all of the values for status:, time-created, time-current, and time-done align, so they should have the appropriate spaces. For example:

```
## Step - ...
      status:
time-created:
time-current:
   time-done:
```

- Steps should not be numbered, so just as shown above.
- So, the `      status:` will be prefixed with 6 spaces
- The `   time-done:` prefixed with 3 spaces.
- The `time-created:` and `time-current:` do not need any space prefixes.

- Below the step, all `      status:` will have a 6-space prefix to align with the properties.
- As well as all `   time-done:` will have a 3-space prefix to align with other properties.

## plan.md structure

Use a single `plan.md` file with these top-level sections, in this order:

- `# Development Plan`
- Then a flat sequence of step sections, in chronological plan order

Rules for this structure:

- Do not use `## Todo`, `## Active`, or `## Done` sections.
- Each step is represented directly as its own `## ... Step - ...` section.
- Keep steps ordered from oldest planned step at the top to newest planned step at the bottom.
 - Use the step heading emoji to represent state, and ensure they are updated as the status of the step changes:
  - `## ■ Step - ...` for not started yet
  - `## ✅ Step - ...` for the step just completed in the current response or the most recently completed step that is still the current focus
  - `## ✔ Step - ...` for older completed steps
- At most one step should normally use `## ✅ Step - ...` at a time.
- Keep these sections in the same file. Do not split them back into multiple files.

## Step Rules

Each step must be defined in a way that does not break the code or existing functionality. To implement a large feature, there can be multiple steps, but none of them should break the code or what is already working.

- Do not have a step about "preparing directories", because this is not a thing in git. Instead, have a step about creating the appropriate files, which will create the directory.

- When only building or updating the plan, do not mark anything done unless the user explicitly asked for implementation work and that work is actually performed in the same response.

## Core flow

- When asked to create or update the plan, do not implement any step. Only create or modify `plan.md`. Implementation work begins only when the user explicitly requests "do next step" or "continue to work on the current step".

- Always implement the topmost `## ■ Step - ...` as part of performing the implementation. Never mark a step as done without implementing it in the same response.

- When implementing or completing a step, ensure the heading emoji is updated to reflect the new state (e.g., from ■ to ✅).

- When beginning work, use the topmost `## ■ Step - ...` as the current implementation target, while simultaneously performing the implementation for that step.

- When the user says "do next step":
  - If the most recent completed step is still marked `## ✅ Step - ...`, convert it to `## ✔ Step - ...` before completing the new step.
  - If a next not-started step exists, implement the topmost `## ■ Step - ...` in the same response and mark it `## ✅ Step - ...` with `      status: done`.
  - If there is no remaining `## ■ Step - ...`, inform the user that all steps are complete.

- When a step is implemented, keep its original not-started content verbatim as much as possible. Only add supplementary sections like `### Work done`, `### Implementation Considerations`, or sub-steps as needed.

- Only add `Implementation Considerations` or such sections if they add meaningful information.

- While continuing work related to the current completed step, append sub-steps and notes to the same step section when appropriate. Do not create another top-level step for that same work unless it is truly a new planned step.

- When a step primarily defines or specifies something, ensure the immediately following `## ■ Step - ...` includes an explicit reference to that definition, pointing to `plan.md` and the relevant completed step heading, so downstream work picks up the defined content.

## Not-started step rules

- Creating or updating the plan is planning-only. Do not begin implementing any step while composing or editing the plan file.

- Each step should be worthy of a commit, and it should not break anything, should be incremental toward the goal, and should be comprehensive. It can be small, but it should be a holistic unit of work.

- Each not-started step uses a heading `## ■ Step - short title for the work`.

- Include `      status: not_started`.

- If available, add `time-created: ...` using the given local time (second precision), and display it like this: `2025-10-26 09:52:21`, no need to show the timezone, and include a space between the date and time.

- After an empty line, provide a concise, complete description of the step.

- Format the step clearly. Often, a paragraph plus a bullet-point list of the task and the files/resources needed is a good way to express what needs to be done.

- When a step will build on a definition or specification from a previous step, include an explicit reference in the body, for example "References: see the definition in `plan.md`, step '✅ Step - ...'". This ensures the next step picks up the defined content from the completed step.

- When a step is implemented, keep the full step in place, change the heading from `## ■ Step - ...` to `## ✅ Step - ...`, change `      status` to `done`, add `   time-done: ...`, and preserve all original content.

## Current completed step and follow-up rules

- The latest completed step may remain marked as `## ✅ Step - ...` so follow-up refinements, fixes, or notes can be attached with minimal edits.

- This is useful in case the user wants new things or if something needs to be fixed, see sub-step below.

- Preserve the original body of the step; do not delete details. Add follow-up sections as needed without altering the original text.

- Keep the heading format as either `## ✅ Step - short title for the work` for the latest completed step or `## ✔ Step - short title for the work` for older completed steps.

- Preserve the original `time-created: ...`.

- Use `   time-done: ...` for the completion time.

- Use the body to track sub-steps, design notes, decisions, and outstanding questions in chronological order.

- Every completed step should include a `### Work done` section that summarizes what was implemented. This summary can be short.

- If the user asks to fix a bug in the current completed step, add a `### Bug fix - SUB_STEP_BUG_SHORT_DESC`, and below it, describe what the issue was and what was fixed.

- When a sub-step is needed because the user asks to fix or add something to the current completed step, use the following section format:

```md
### sub-step - SUB_STEP_SHORT_DESCRIPTION
time-current: ....

#### User ask

USER_ASK

#### AI Answer

SUMMARY_OF_WHAT_WAS_DONE_AND_WHY_THERE_WAS_AN_ISSUE_IF_ISSUE.

#### Implementation Considerations

IF_NEEDED_OTHER_SUB_STEP_SECTION_FOR_ADDITIONAL_INFORMATION
```

- Add the `#### Implementation Considerations` only when needed as well, same as for the top step.

- When the user requests to move on, for example, do next step:
  - If there are no sub-steps, the step may stay as-is except that it should be downgraded from `## ✅ Step - ...` to `## ✔ Step - ...` once a newer step is completed.
  - If there are many sub-steps or back-and-forth, consolidate them into a concise set of instructions or summary before the step becomes an older completed step, except when the step is primarily defining or specifying something. In that case, do not consolidate, carry the entire content verbatim so that subsequent steps have full information.

## Done step rules

- Only steps that were previously planned as `## ■ Step - ...` can become completed steps.

- Use the same flat ordering in the file.

- Set `      status: done`. Keep the original `time-created: ...` and add `   time-done: ...`.

- The most recently completed or currently-followed-up step should use `## ✅ Step - ...`.

- Older completed steps should use `## ✔ Step - ...`.

- If there were no additional sub-steps, carry the content over verbatim so nothing is lost.

- Provide a `### Work done` section capturing key details, decisions, and answers without the iterative back-and-forth. This summary can be concise.

- For steps whose primary purpose is to define or specify something, do not consolidate or shorten the main content. Carry the entire content verbatim so subsequent steps have the full reference for downstream work.

- Keep steps listed from oldest to newest, newest at the bottom.
