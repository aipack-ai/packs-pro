# Rules to create/update the plan files

This file gives the rules on how to manage the plan files, the `plan-todo.md` and `plan-done.md` files. 

- `plan-todo.md` - Contains the steps of a plan that are not done yet, and order from top to bottom. Meaning the top most step are to be done first. 

- `plan-done.md` - Contains the steps that have been completed. it follow the same format as the plan-todo steps, but with different `status` and `time`

By default, the `plan-todo.md` and `plan-done.md` are located in the same folder as the `_plan-rules.md` folder. 

The user might ask to create or update the plan, or perform a step. When performing a step, perform the step from the top. 

When a step is done, and file updated, also add in the response, at end a suggest git commit for the step. 

Show the suggested gitt commit command and message. 
- For example `git commit -a -m ". chat_response - Fix doc typos and provider_model_iden doc"`
- The first character is `.` for minor | `-` for Fix | `+` for Addition | `^` for Improvement | `!` for Change | `*` for Refactor
- Commit messages should be concise, starting with the first character, then the module or topic, followed by a dash (`-`), and a short description.
- Prefix it with "Suggested commit:"
- Do not mention the plan or history in the commit message, as that's not its concern.

## plan-todo.md rules

- The `plan-todo.md` is a work plan file that is used to describe the work that needs to be done
- The format is that each step is under `## Step - short title for the work`
- Followed by `status: not_started`
- If you have today's date, add below it `time-created: ...` with the local date/time formatted in RFC 3339 (second precision)
- Then an empty line, and the description of the step (what needs to be done). Concise but complete.
- When it is implemented, move that section to the `work-history.md` with `status: done` and remove it from the list below.
- We go from the top down, meaning the next step to be done is at the top.
- If there is a missing file, update the work plan, mark the plan "in_progress", and state the blocker; then, on the next run, the user will probably solve the blocker.

## plan-done.md rules

- This is where the completed work goes.
- Similar format to the `plan-todo.md`.
- Below the `time-created: ...` add a `time-done: ...` so that we know when it was created and done.
- This file lists the steps from oldest to newest, with the newest at the bottom.


