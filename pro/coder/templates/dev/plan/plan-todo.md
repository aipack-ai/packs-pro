# Work Plan Context

- Here is a work plan file which is used to describe the work that need to be done

- The format is that each step is under `## Step - short title for the work`

- Followed by `status: not_started` 

- If you have the "today", just below add `time: ...` with the date/time Local formatted, in RFC 3339 (second precision)

- Then empty line, and the description of the step (what's need to be done). Concise but complete.

- When it is implemented, move that section to the `work-history.md` with `status: done` and remove it from the list below. 

- We go top down, meaning next step to be done is on top. 

- If there is a missingfile, update the work-plan, mark the plan "in_progress" and say the blocker, and then, on next run, the user will probably solve the blocker. 

- When you perform the step, after all of the file update, give an good git commit command to do like
  - `git commit -a -m ". chat_response - Fix doc typos and provider_model_iden doc`
  - The first char is `.` minor | `-` Fix | `+` Addition | `^` improvement | `!` Change | `*` Refactor
  - Do not add mention the plan/history in commit message (not of its concern)




