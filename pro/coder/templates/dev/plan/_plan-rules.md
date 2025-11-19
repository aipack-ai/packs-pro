# Rules for creating/updating the plan files

This file defines how to manage the plan files: `path/to/plan-1-todo-steps.md`, `path/to/plan-2-current-step.md`, and `path/to/plan-3-done-steps.md`.

- `path/to/plan-1-todo-steps.md` lists upcoming steps, ordered top to bottom. The topmost item is the next step to activate.

- `path/to/plan-2-current-step.md` holds the single step in progress, marked `      status: current`. It is created only when implementation begins, by moving the topmost todo step into it (typically triggered by "do next step" or an explicit request to continue work). It represents what was worked on in the latest turn and what is currently being worked on by the AI. It is not a queue of upcoming steps. If work spans multiple turns, add sub-steps here.

- `path/to/plan-3-done-steps.md` archives completed steps, marked `      status: done`, with a concise summary.

Current is created when implementation starts, and exists only to reflect the work actively being performed by the AI, including what has just been implemented. Do not treat the current step as the "next to do". It mirrors the work just performed and the ongoing work until the user says "do next step" or "continue to work on current step". Do not create or keep a current step during planning-only phases.

- When the user asks to do the next step, but there is nothing in the todo file and a current step in the current-step file, simply move the current step to the done file as usual, and inform the user that everything is completed.

- If the user continues to ask to do something when there is nothing in the todo file, just say that there are no more items in the plan-1-todo-steps file.

- When the user says there is a bug in the current step, fix the bug and update the current step with the sub-step as defined below. The same applies if the user says it wants to add something new to the current step. Just a sub-step, as defined below. 


**Imports on files location**

Unless specified otherwise, these three files live in the same directory as this `path/to/_plan-rules.md` file.

So, for example, if the _plan-rules.md file path is `some/path/to/_plan-rules.md` then we will have `some/path/to/plan-1-plan-steps.md` and similar for the other files. 

So, plan-1-plan-steps, etc. are in the same folder as the _plan-rules.md.

**Markdown formatting rules:** 

- Favor bullet point format when multiple points per step need to be given. 
- Use `-` character for bullet points
- When bullet points have a long line or sub-bullet points, include an empty line between the top-level bullet points
- For headings, except for the `## Step` and `### Sub Step`, leave exactly one empty line after the heading
    - For `## Step ...` and `### Sub Step ...`, do not insert any empty line after the heading. The `      status: ...` line must be immediately after the heading with no blank line in between, followed by any `time-...` fields on subsequent lines. 

- Info alignment: It is important that the values of all of the values for status:, time-created, time-current, and time-done, align, so they should have the appropriate spaces. For example: 

```
## Step - ...
      status: 
time-created:
   time-done:
```

- Steps should not be numbered, so just as shown above.
- So, the `      status:` will be prefixed with 6 spaces
- the `   time-done:` prefixed with 3 spaces
- and `time-created:` or `time-current:` does not need any space prefixes. 


- Below the step, all `       status:` will have a 6-space prefix to align with the properties
- As well as all `   time-done:` will have a 3-space prefix to align with other properties

**Step Rules:** Each step must be defined in a way that does not break the code or existing functionality. To implement a large feature, there can be multiple steps, but none of them should break the code or what is already working.

**Other notes:**

- Do not have a step about "preparing directories", because this is not a thing in git. Instead, have a step about creating the appropriate files, which will create the directory. 

- Also, when only building the plan-1-todo-steps, do not create empty plan-2-current-step and plan-3-done-steps if they do not exist. Create them only when needed.

## Core flow

- When asked to create or update the plan, do not implement any step. Only create or modify the plan files. Implementation work begins only when the user explicitly requests "do next step" or "continue to work on current step".

- Always move a step from todo to current before doing any work on it. Never move a todo step directly to done.

- Create `path/to/plan-2-current-step.md` only when beginning implementation. When beginning work, move the topmost step from `path/to/plan-1-todo-steps.md` into it and set `      status: current`.

- When the user says "do next step":
  - If a current step exists, finalize it, move it to done with `      status: done`. If a next todo step exists, activate the topmost todo as the new current. If there are no remaining todo steps, inform the user that there are no more steps to be done.
  - If there is no current step, activate the topmost todo as current and proceed.

- When a step becomes current, keep its original todo content verbatim. Only add supplementary sections like `### Implementation Considerations` or sub-steps as needed.

- Only add `Implementation Considerations` or such sections if they add meaningful information. 

- While continuing work on the current step, append sub-steps and notes to the same section. Do not create another top-level step.
- When a step primarily defines or specifies something, ensure the immediately following todo step includes an explicit reference to that definition, pointing to plan-2-current-step.md or plan-3-done-steps.md and the step heading, so downstream work picks up the defined content.

## plan-1-todo-steps.md rules

- Creating or updating the plan is planning-only. Do not begin implementing any step while composing or editing the plan files.
- Each step uses a heading `## Step - short title for the work`.

- Include `      status: not_started`.

- If available, add `time-created: ...` using the given local time (second precision), and display it like this: `2025-10-26 09:52:21` (no need to show the timezone, and include a space between the date and time).

- After an empty line, provide a concise, complete description of the step.
- When a step will build on a definition or specification from a previous step, include an explicit reference in the body, for example "References: see the definition in plan-2-current-step.md or plan-3-done-steps.md, step 'Step - ...'". This ensures the next step picks up the defined content from current or done.

- When a step is activated, move the entire step to `path/to/plan-2-current-step.md`, change `      status` to `current`, and remove it from todo. Preserve all original content.

## plan-2-current-step.md rules

- Contains exactly one step with `      status: current` only while implementation is in progress. If there is no active implementation, this file may be absent or empty. Create it and activate the topmost todo only when beginning implementation.

- This file is here in case the user wants new things or if something needs to be fixed (see sub-step below)

- Copy the full body from todo when the step becomes current; do not delete details. Add follow-up sections as needed without altering the original text.

- Keep the same heading format `## Step - short title for the work`.

- Preserve the original `time-created: ...`. 

- Add `time-current: ...` just below

- Use the body to track sub-steps, design notes, decisions, and outstanding questions in chronological order.

- When a sub-step is needed because the user asks to fix or add something to the current step, use the following section format:

<sub_step_example_format>
### sub-step - SUB_STEP_SHORT_DESCRIPTION
time-current: ....

#### User ask

USER_ASK

#### AI Answer

SUMMARY_OF_WHAT_WAS_DONE_AND_WHY_THERE_WAS_AN_ISSUE_IF_ISSUE. 

#### Implementation Considerations

IF_NEEDED_OTHER_SUB_STEP_SECTION_FOR_ADDITIONAL_INFORMATION
</sub_step_example_format>

- Add the `#### Implementation Considerations` only when needed as well (same as for the top step)

- When the user requests to move on (e.g., do next step):
  - If there are no sub-steps, move the step as-is to done with `      status: done`.
  - If there are many sub-steps or back-and-forth, consolidate them into a concise set of instructions or summary, then mark `      status: done` and archive, except when the step is primarily defining or specifying something. In that case, do not consolidate, carry the entire content verbatim into done so that subsequent steps have full information.

- After archiving the current step, if a next todo exists, immediately activate the topmost todo as the new current to continue the flow. If there are no remaining todo steps, inform the user that there are no more steps to be done.


## plan-3-done-steps.md rules

- Only steps that have been in `path/to/plan-2-current-step.md` as `      status: current` can be moved here.

- Use the same heading format as the other files.

- Set `      status: done`. Keep the original `time-created: ...`, the `time-current` becomes the `time-done: ...` when moved to the plan-3-done-steps file (if there were sub-steps in the current step, then the last time-current becomes time-done).

- If there were no additional sub-steps while current, carry the content over verbatim so nothing is lost.

- Provide a consolidated summary capturing key details, decisions, and answers without the iterative back-and-forth.

- For steps whose primary purpose is to define or specify something, do not consolidate or shorten. Carry the entire content verbatim so subsequent steps have the full reference for downstream work.

- List steps from oldest to newest, newest at the bottom.