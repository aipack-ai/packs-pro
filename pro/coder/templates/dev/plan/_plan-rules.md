# Rules for creating/updating the plan files

This file provides the rules for managing the plan files: `path/to/plan-1-todo.md`, `path/to/plan-2-current.md`, and `path/to/plan-3-done.md`. 

- `path/to/plan-1-todo.md` - Contains the ordered list of upcoming steps that are not started yet. The topmost step is the next one to activate. 

- `path/to/plan-2-current.md` - Contains the step that is currently being executed with status `current`, along with its working notes and sub-steps. 

- `path/to/plan-3-done.md` - Contains the steps that have been fully completed, summarized, and marked as `done`.

Except if the user specify otherwise, the path (i.e. `path/to/`) of the `path/to/plan-1-todo.md`, `path/to/plan-2-current.md`, and `path/to/plan-3-done.md` files are located in the same directory as this `path/to/_plan-rules.md` file. 

The data flow moves from `plan-1-todo.md` to `plan-2-current.md`, then to `plan-3-done.md`. When a step leaves the todo file, it must first be copied into the current file and marked `status: current` before any execution notes or work begin. When the current step is finished and the user requests the next step, consolidate it and move it to the done file before promoting the next todo entry, never skipping the current file stage. If `plan-2-current.md` is missing or empty, create it and insert the activated step with `status: current` before continuing. Do not mark a todo step as done or move it to `plan-3-done.md` until it has been recorded in `plan-2-current.md`, and do not use placeholder text such as "no active step" in place of a current step.

When the user requests to "do next step" or something similar, always move the topmost entry from `plan-1-todo.md` into `plan-2-current.md` (creating the file if it does not exist) and update its status to `current` before any work begins. Only after the user asks again for the next step should the current entry be finalized, moved to `plan-3-done.md`, and replaced by the next todo item. Never move a todo entry directly into `plan-3-done.md`. When promoting a step between files, copy all original content verbatim and only augment it with additional subsections (for example, `### Implementation Considerations`) so that no planned detail is lost.

A user might ask to create or update the plan, or to perform a step. When performing a step, do the topmost step first. 

When the user ask to create or update the plan file(s), do not do any steps, just update the needed plan files. 

Make sure to follow the code block notation with the file name so that the file get created. 

## plan-1-todo.md rules

- The `plan-1-todo.md` file is a work plan used to describe tasks that need to be done next.
- Each step is under a heading in the form `## Step - short title for the work`
- Followed by `status: not_started`
- If you have today's date, add `time-created: ...` below it, using the local date/time formatted in RFC 3339 (second precision)
- Then an empty line and a concise but complete description of the step (what needs to be done).
- When a step becomes active, move the entire step to `plan-2-current.md`, update its `status` to `current`, and remove it from this file. Keep every detail from the original todo entry intact when copying, and only append new subsections such as `### Implementation Considerations` if needed for extra context so that nothing is lost. Do not send a not_started step directly to `plan-3-done.md`; it must exist in the current plan first.
- Steps are ordered top to bottom, so the next step to be done is at the top.
- If a file is missing, update the work plan, mark the plan as "in_progress", and state the blocker. On the next run, the user will likely resolve the blocker.

## plan-2-current.md rules

- The `plan-2-current.md` file holds the step that is currently in progress with `status: current`.
- If the `plan-2-current.md` file does not exist, create it and move the topmost step from `plan-1-todo.md` into it before logging any progress or marking any step as done.
- Every step pulled from `plan-1-todo.md` must be written into this file and marked `status: current` before any progress can be logged or the step can later be archived.
- Retain the full body from the todo entry when it becomes current, adding follow-up sections (for example, `### Implementation Considerations`) only as supplementary context without deleting the original content.
- Keep the same heading format `## Step - short title for the work`.
- Preserve the `time-created: ...` value from when the step was first planned, and add any additional timestamps when relevant, formatted in RFC 3339 (second precision).
- Use the body of the section to track sub-steps, communication summaries, design notes, and outstanding questions so the full context stays with the active step.
  - Add sub-bullets or nested headings to capture each follow-up action or clarification in chronological order.
- When the user wants to continue working on the current step, append the new context under the same section without creating a new top-level step.
- Do not leave `plan-2-current.md` with placeholder text such as "no active step"; always maintain the real current step content until it is completed and moved to `plan-3-done.md`.
- When the user requests to move to the next step, prepare a consolidated summary of the work (without noise), change `status: current` to `status: done`, move the step to `plan-3-done.md`, and promote the next step from `plan-1-todo.md` into this file with `status: current`. If there were no additional sub-steps or discussion while the step was current, move the content verbatim so that nothing from the original plan is lost; otherwise consolidate the iterative notes into a concise resolution before archiving.

## When step is in current or revision on current

When a step in `plan-2-current.md` is finalized, moved to `plan-3-done.md`, and the files are updated, also add to the response, at the end, a suggested git commit for the change. 

Show the suggested git commit command that the should may want to do for this step, formatted in the  'suggested_git_command' tag. For example:  

<suggested_git_command>
git commit -a -m ". chat_response - Fix doc typos and provider_model_iden doc"
</suggested_git_command>

Here is the git commit messageformatting rules:

- The first character is `.` for minor, `-` for fix, `+` for addition, `^` for improvement, `!` for change, and `*` for refactor
- Commit messages should be concise, starting with the first character, space, then the module or topic, space, followed by a dash (`-`), space, and a short description.
- Prefix it with "Suggested commit:"
- Do not mention the plan or history in the commit message, as that's not its concern.

## plan-3-done.md rules

- This is where completed work goes after leaving `plan-2-current.md`; only steps that have been recorded there as `status: current` may be moved here.
- Use the same heading format as the other plan files.
- Set `status: done`, keep the original `time-created: ...`, and add a `time-done: ...` when the step is finalized.
- If the step had no additional sub-steps or discussion while current, carry the content over verbatim so that no information from the original plan is lost.
- Provide a consolidated summary that captures the key implementation details, decisions, and user answers without the iterative back and forth.
- List the steps from oldest to newest, with the newest at the bottom.