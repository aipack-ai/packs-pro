# Rules & Skill for creating and following a dev plan

## When to use this skill

Use this file when the user need to create, follow, implement the development plan.

## Key Rules

This file defines how to manage the plan file. The plan flow now uses a single `plan.md` file.

- `plan.md` **must always live in the same directory as this `_plan-rules.md` file**.

- Create, read, and modify `plan.md` in the same directory as the `_plan-rules.md` file. Never place it in any other directory.

- `plan.md` contains the full plan state in one place, including upcoming steps, the current active step when there is one, and completed steps.

Important note:

- Make sure when asked to implement (e.g., do, work, ...) the next step or to work/fix active step, the plan file only gets updated if work has been done, or if a note needs to be added in the active step. Do not update the plan file if you did not do any implementation.

- If you cannot do the next step because there is not enough information, just tell the user using the `<missing_files>` tag or in the response, but do not update the plan file, except if asked by the user to say why implementation was not done for example.

- Only move a todo step to active when implementation is actually performed in that same response.

- Keep the active step as a real in-progress implementation mirror, not a planning transition artifact.

- The active step exists only to reflect the work actively being performed by the AI, including what has just been implemented.
Do not treat the active step as the "next to do". It mirrors the work just performed and the ongoing work until the user says "do next step" or "continue to work on active step". Do not create or keep an active step during planning-only phases.

- When the user asks a question about the active step, add this information to the active step section in `plan.md`.

- Only move something to active if it can be implemented. If the next step cannot be implemented, due to missing files or anything else, then just tell the user in the prompt or note it as missing files, but do not edit the plan file.

- When the user asks to do, that is, implement, the next step, but there is no remaining todo step and there is an active step, simply move the active step to done as usual, and inform the user that everything is complete.

- If the user continues to ask to do something when there is no remaining todo step, just say that there are no more items in `plan.md`.

- When the user says there is a bug in the active step, fix the bug and update the active step with the sub-step as defined below. The same applies if the user says it wants to add something new to the active step. Just a sub-step, as defined below.

## Markdown formatting rules

- Favor bullet point format for the step content when appropriate.
- Use `-` character for bullet points
- When bullet points have a long line or sub-bullet points, include an empty line between the top-level bullet points
- For headings, except for the `## Step` and `### sub-step`, leave exactly one empty line after the heading.
  - For `## Step ...` and `### sub-step ...`, do not insert any empty line after the heading. The `      status: ...` line must be immediately after the heading with no blank line in between, followed by any `time-...` fields on subsequent lines.

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
- `## Todo`
- `## Active`
- `## Done`

Rules for these sections:

- `## Todo` lists upcoming steps, ordered top to bottom. The topmost item is the next step to activate.
- `## Active` contains exactly one active step while implementation is in progress, or a short placeholder such as `- None` when there is no active step.
- `## Done` contains completed steps from oldest to newest, newest at the bottom.
- Keep these sections in the same file. Do not split them back into multiple files.

## Step Rules

Each step must be defined in a way that does not break the code or existing functionality. To implement a large feature, there can be multiple steps, but none of them should break the code or what is already working.

- Do not have a step about "preparing directories", because this is not a thing in git. Instead, have a step about creating the appropriate files, which will create the directory.

- When only building or updating the plan, do not mark anything active or done unless the user explicitly asked for implementation work and that work is actually performed in the same response.

## Core flow

- When asked to create or update the plan, do not implement any step. Only create or modify `plan.md`. Implementation work begins only when the user explicitly requests "do next step" or "continue to work on active step".

- Always move a step from todo to active as part of performing the implementation. Never move a todo step to active without implementing it in the same response. Never move a todo step directly to done.

- When beginning work, move the topmost step from the `## Todo` section into the `## Active` section and set `      status: active`, while simultaneously performing the implementation for that step.

- When the user says "do next step":
  - If an active step exists, finalize it and move it to the `## Done` section with `      status: done`.
  - If a next todo step exists, activate the topmost todo as the new active step and implement it in the same response.
  - If the todo section is empty, do not leave the active step in place. Move it to done as described above, and inform the user that all steps are complete.
  - If there is no active step, activate the topmost todo as active and implement it immediately in the same response.

- When a step becomes active, keep its original todo content verbatim. Only add supplementary sections like `### Implementation Considerations` or sub-steps as needed.

- Only add `Implementation Considerations` or such sections if they add meaningful information.

- While continuing work on the active step, append sub-steps and notes to the same step section. Do not create another top-level step.

- When a step primarily defines or specifies something, ensure the immediately following todo step includes an explicit reference to that definition, pointing to `plan.md` and the relevant done or active step heading, so downstream work picks up the defined content.

## Todo step rules

- Creating or updating the plan is planning-only. Do not begin implementing any step while composing or editing the plan file.

- Each step should be worthy of a commit, and it should not break anything, should be incremental toward the goal, and should be comprehensive. It can be small, but it should be a holistic unit of work.

- Each step uses a heading `## Step - short title for the work`.

- Include `      status: not_started`.

- If available, add `time-created: ...` using the given local time (second precision), and display it like this: `2025-10-26 09:52:21`, no need to show the timezone, and include a space between the date and time.

- After an empty line, provide a concise, complete description of the step.

- Format the step clearly. Often, a paragraph plus a bullet-point list of the task and the files/resources needed is a good way to express what needs to be done.

- When a step will build on a definition or specification from a previous step, include an explicit reference in the body, for example "References: see the definition in `plan.md`, step 'Step - ...'". This ensures the next step picks up the defined content from active or done.

- When a step is activated, move the entire step from the `## Todo` section to the `## Active` section, change `      status` to `active`, and remove it from todo while performing its implementation in the same response. Preserve all original content.

## Active step rules

- The `## Active` section contains exactly one step with `      status: active` only while implementation is in progress. If there is no active implementation, the section should be empty or use a short placeholder such as `- None`.

- This section is here in case the user wants new things or if something needs to be fixed, see sub-step below.

- Copy the full body from todo when the step becomes active; do not delete details. Add follow-up sections as needed without altering the original text.

- Keep the same heading format `## Step - short title for the work`.

- Preserve the original `time-created: ...`.

- Add `time-current: ...` just below.

- Use the body to track sub-steps, design notes, decisions, and outstanding questions in chronological order.

- If the user asks to fix a bug in the active step, add a `### Bug fix - SUB_STEP_BUG_SHORT_DESC`, and below it, describe what the issue was and what was fixed.

- When a sub-step is needed because the user asks to fix or add something to the active step, use the following section format:

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
  - If there are no sub-steps, move the step as-is to the `## Done` section with `      status: done`.
  - If there are many sub-steps or back-and-forth, consolidate them into a concise set of instructions or summary, then mark `      status: done` and archive, except when the step is primarily defining or specifying something. In that case, do not consolidate, carry the entire content verbatim into done so that subsequent steps have full information.

- After archiving the active step:
  - If a next todo exists, immediately activate the topmost todo as the new active step and implement it in the same response.
  - If the todo section is empty, the active step has already been moved to done. Inform the user that all steps are complete. Do not leave a stale active step behind.

## Done step rules

- Only steps that have been active can be moved to the `## Done` section.

- Use the same heading format as the other sections.

- Set `      status: done`. Keep the original `time-created: ...`, the `time-current` becomes the `time-done: ...` when moved to the done section. If there were sub-steps in the active step, then the last `time-current` becomes `time-done`.

- If there were no additional sub-steps while active, carry the content over verbatim so nothing is lost.

- Provide a consolidated summary capturing key details, decisions, and answers without the iterative back-and-forth.

- For steps whose primary purpose is to define or specify something, do not consolidate or shorten. Carry the entire content verbatim so subsequent steps have the full reference for downstream work.

- List steps from oldest to newest, newest at the bottom.
