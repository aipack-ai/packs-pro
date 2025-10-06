# Rules for creating/updating the plan files

This file provides the rules for managing the plan files: `plan-todo.md` and `plan-done.md`. 

- `plan-todo.md` - Contains the steps of a plan that are not done yet, ordered from top to bottom. This means the topmost step is to be done first. 

- `plan-done.md` - Contains the steps that have been completed. It follows the same format as the plan-todo steps, but with different `status` and `time`.

By default, the `plan-todo.md` and `plan-done.md` files are located in the same folder as the `_plan-rules.md` file. 

A user might ask to create or update the plan, or to perform a step. When performing a step, do the topmost step first. 

When a step is completed and the files are updated, also add to the response, at the end, a suggested git commit for the change. 

Show the suggested git commit command that the should may want to do for this step, formatted like the example show in 'suggested_git_command_example' tag (make sure exact format). 

<suggested_git_command_example>
Suggested commit: 

```sh
#!git-commit-suggestion
git commit -a -m ". chat_response - Fix doc typos and provider_model_iden doc"
```
</suggested_git_command_example>

Note that the code block is only 2 lines, no empty line. 

Here is the git commit messageformatting rules:

- The first character is `.` for minor, `-` for fix, `+` for addition, `^` for improvement, `!` for change, and `*` for refactor
- Commit messages should be concise, starting with the first character, space, then the module or topic, space, followed by a dash (`-`), space, and a short description.
- Prefix it with "Suggested commit:"
- Do not mention the plan or history in the commit message, as that's not its concern.

## plan-todo.md rules

- The `plan-todo.md` file is a work plan used to describe tasks that need to be done.
- Each step is under a heading in the form `## Step - short title for the work`
- Followed by `status: not_started`
- If you have today's date, add `time-created: ...` below it, using the local date/time formatted in RFC 3339 (second precision)
- Then an empty line and a concise but complete description of the step (what needs to be done).
- When it is implemented, move that section to the `work-history.md` file with `status: done` and remove it from the list below.
- Steps are ordered top to bottom, so the next step to be done is at the top.
- If a file is missing, update the work plan, mark the plan as "in_progress", and state the blocker. On the next run, the user will likely resolve the blocker.
- Each step must represent a meaningful, self-contained piece of progress — it should compile or run successfully, produce visible or structural changes (in UI or architecture), and clearly demonstrate advancement from the previous step.


## plan-done.md rules

- This is where completed work goes.
- Use a similar format to `plan-todo.md`.
- Below `time-created: ...`, add a `time-done: ...` so we know when it was created and completed.
- This file lists the steps from oldest to newest, with the newest at the bottom.