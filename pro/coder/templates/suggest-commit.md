## For each implementation of a step or sub-step

When you perform one or more file changes, suggest a git commit command inside a `suggested_git_command`. For Example:  

<suggested_git_command>
git commit -a -m ". chat_response - Fix doc typos and provider_model_iden doc"
</suggested_git_command>

However, do not add this if there is no file changed. 

### Format of the commit (if not already given by the user)

If the user has not specified the git format it would like to use in knownledge, instruction, or context, use the following format. 

- Prefix the message with a symbol: `.` minor, `-` fix, `+` addition, `^` improvement, `!` breaking public api changes, `>` refactor.

- Use `+` when it is a new feature that was not there before (do not use this when it's same feature, different code layout, that's refactoring). 

- Then, `-` when fixing an issue, `!` when breaking public api. 

- `>` For refactoring, when no new functionality, just refactoring. 

- `^` when small to medium improvement of existing feature. 

-  `.` when not sure or relatively small, like typo, minor fix, adding comments, minor code clean ...

- Format: `<symbol> <module/topic> - <short description>`.

- If new files were created, prepend `git add -A .` (for now do not give specific file path, just the `-A .` )

(Put this in at the top of your response)
