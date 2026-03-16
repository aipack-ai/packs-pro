# Rules for creating/updating the plan files

This file defines how to manage the plan files.  
All three plan files **must always live in the same directory as this `_plan-rules.md` file**:

- `plan-1-todo-steps.md`
- `plan-2-active-step.md`
- `plan-3-done-steps.md`

Create, read, and modify these plan files **in the same directory** as the `_plan-rules.md` file. Never place them in any other directory.

- `plan-1-todo-steps.md` lists upcoming steps, ordered top to bottom. The topmost item is the next step to activate.

- `plan-2-active-step.md` when a new step is implemented, it is taken from `plan-1-todo-steps.md` and put in this file. This way, the user can see what is implemented. The user can also ask to work more on this active step if there is a bug or something. Otherwise, it moves to `plan-3-done-steps.md` when a new step is completed and moved from this file.

- `plan-3-done-steps.md` archives completed steps, marked `      status: done`, with a concise summary. (can be created when moving the first step to it)

Important note: 

- Make sure when asked to implement (e.g., do, work, ...) the next step or to work/fix active step, the plan files only get updated if work has been done (or if a note needs to be added in active). Do not update the plan files if you did not do any implementation.

- If you cannot do the next step because there is not enough information, just tell the user using the `<missing_files>` tag or in the response, but do not update the plan files, except if asked by the user to say why implementation was not done for example.

- Only move todo to active when implementation is actually performed in that same response.

- Keep active as a real in-progress implementation mirror, not a planning transition artifact.

- `plan-2-active-step.md` exists only to reflect the work actively being performed by the AI, including what has just been implemented.  
Do not treat the active step as the "next to do". It mirrors the work just performed and the ongoing work until the user says "do next step" or "continue to work on active step". Do not create or keep an active step during planning-only phases.

- When the user asks a question about the active step, add this information to the active step file. 

- Only move something to active steps if it can be implemented. If the next step cannot be implemented, due to missing files or anything else, then just tell the user in the prompt or note it as missing files, but do not edit the plan files. 

- When the user asks to do, that is, implement, the next step, but there is nothing in the plan-1-todo file and there is an active step in the active-step file, simply move the active step to the done file as usual, and inform the user that everything is complete.

- If the user continues to ask to do something when there is nothing in the todo file, just say that there are no more items in the plan-1-todo-steps file.

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


## Step Rules

Each step must be defined in a way that does not break the code or existing functionality. To implement a large feature, there can be multiple steps, but none of them should break the code or what is already working.

- Do not have a step about "preparing directories", because this is not a thing in git. Instead, have a step about creating the appropriate files, which will create the directory. 

- Also, when only building the plan-1-todo-steps, do not create empty plan-2-active-step and plan-3-done-steps if they do not exist. Create them only when needed.


## Core flow

- When asked to create or update the plan, do not implement any step. Only create or modify the plan files. Implementation work begins only when the user explicitly requests "do next step" or "continue to work on active step".

- Always move a step from todo to active **as part of performing the implementation**. Never move a todo step to active without implementing it in the same response. Never move a todo step directly to done.

- Create `plan-2-active-step.md` only when beginning implementation. When beginning work, move the topmost step from `plan-1-todo-steps.md` into it and set `      status: active`, **while simultaneously performing the implementation for that step**.

- When the user says "do next step":
  - If an active step exists, finalize it and move it to done with `      status: done`.
    - If a next todo step exists, activate the topmost todo as the new active step **and implement it in the same response**.
    - If the todo file is empty (no remaining todo steps), do **not** leave the active step in place. Move it to done as described above, and inform the user that all steps are complete.
  - If there is no active step, activate the topmost todo as active **and implement it immediately in the same response**.

- When a step becomes active, keep its original todo content verbatim. Only add supplementary sections like `### Implementation Considerations` or sub-steps as needed.

- Only add `Implementation Considerations` or such sections if they add meaningful information. 

- While continuing work on the active step, append sub-steps and notes to the same section. Do not create another top-level step.
- When a step primarily defines or specifies something, ensure the immediately following todo step includes an explicit reference to that definition, pointing to plan-2-active-step.md or plan-3-done-steps.md and the step heading, so downstream work picks up the defined content.


## plan-1-todo-steps.md rules

- Creating or updating the plan is planning-only. Do not begin implementing any step while composing or editing the plan files.

- Each step should be worthy of a commit, and it should not break anything, should be incremental toward the goal, and should be comprehensive (it can be small, but it should be a holistic unit of work)

- Each step uses a heading `## Step - short title for the work`.

- Include `      status: not_started`.

- If available, add `time-created: ...` using the given local time (second precision), and display it like this: `2025-10-26 09:52:21` (no need to show the timezone, and include a space between the date and time).

- After an empty line, provide a concise, complete description of the step.

- When a step will build on a definition or specification from a previous step, include an explicit reference in the body, for example "References: see the definition in plan-2-active-step.md or plan-3-done-steps.md, step 'Step - ...'". This ensures the next step picks up the defined content from active or done.

- When a step is activated, move the entire step to `plan-2-active-step.md`, change `      status` to `active`, and remove it from todo **while performing its implementation in the same response**. Preserve all original content.


## plan-2-active-step.md rules

- Contains exactly one step with `      status: active` only while implementation is in progress. If there is no active implementation, this file may be absent or empty. Create it and activate the topmost todo **only when performing implementation**.

- This file is here in case the user wants new things or if something needs to be fixed (see sub-step below)

- Copy the full body from todo when the step becomes active; do not delete details. Add follow-up sections as needed without altering the original text.

- Keep the same heading format `## Step - short title for the work`.

- Preserve the original `time-created: ...`. 

- Add `time-current: ...` just below

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

- Add the `#### Implementation Considerations` only when needed as well (same as for the top step)

- When the user requests to move on (e.g., do next step):
  - If there are no sub-steps, move the step as-is to done with `      status: done`.
  - If there are many sub-steps or back-and-forth, consolidate them into a concise set of instructions or summary, then mark `      status: done` and archive, except when the step is primarily defining or specifying something. In that case, do not consolidate, carry the entire content verbatim into done so that subsequent steps have full information.

- After archiving the active step:
  - If a next todo exists, immediately activate the topmost todo as the new active step **and implement it in the same response**.
  - If the todo file is empty (no remaining todo steps), the active step has already been moved to done. Inform the user that all steps are complete. Do not leave a stale active step behind.


## plan-3-done-steps.md rules

- Only steps that have been in `plan-2-active-step.md` as `      status: active` can be moved here.

- Use the same heading format as the other files.

- Set `      status: done`. Keep the original `time-created: ...`, the `time-current` becomes the `time-done: ...` when moved to the plan-3-done-steps file (if there were sub-steps in the active step, then the last time-current becomes time-done).

- If there were no additional sub-steps while active, carry the content over verbatim so nothing is lost.

- Provide a consolidated summary capturing key details, decisions, and answers without the iterative back-and-forth.

- For steps whose primary purpose is to define or specify something, do not consolidate or shorten. Carry the entire content verbatim so subsequent steps have the full reference for downstream work.

- List steps from oldest to newest, newest at the bottom.
