# Work Plan Context

- Here is a work plan file that is used to describe the work that needs to be done

- The format is that each step is under `## Step - short title for the work`

- Followed by `status: not_started`

- If you have today's date, add below it `time: ...` with the local date/time formatted in RFC 3339 (second precision)

- Then an empty line, and the description of the step (what needs to be done). Concise but complete.

- When it is implemented, move that section to the `work-history.md` with `status: done` and remove it from the list below.

- We go from the top down, meaning the next step to be done is at the top.

- If there is a missing file, update the work plan, mark the plan "in_progress", and state the blocker; then, on the next run, the user will probably solve the blocker.

- When you perform the step, after updating the file, provide a good git commit command to use, for example
  - `git commit -a -m ". chat_response - Fix doc typos and provider_model_iden doc"`
  - The first character is `.` for minor | `-` for Fix | `+` for Addition | `^` for Improvement | `!` for Change | `*` for Refactor
  - Do not mention the plan/history in the commit message (not its concern)