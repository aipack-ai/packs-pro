# AI PACKS for `pro@` AI Pack Namespaces

This is the repository for Production Coding Packs, developed and maintained by Jeremy Chone and the [AIPACK](https://aipack.ai) & [BriteSnow team](https://britesnow.com) teams.

## Overview

The first main pack is `pro@coder`, and like all future packs in this `pro@` AI Pack namespace, they will be tailored toward Production Coding (versus Vibe Coding).

- Start a new project, but with production in mind from the start.

- Work on a big code base (10k lines or more) with the "globs lensing" parametric prompt (i.e., `knowledge_globs` and ``).

This is accomplished in a few ways:

- Interactive packs/agents will have a parametric prompt like `pro@coder` with the `coder-prompt.md` usually created in the project `.aipack/.prompt/pro@coder/coder-prompt.md`.
- These parametric prompt files allow the agent to let the user customize its behavior with some agent-specific parameters.
- For example, in `pro@coder`, the user can specify which model they want to use per request, focus the agent only on some of the files (with the `context_globs`), and even customize concurrency with `working_globs` and `working_concurrency`.
- `pro@coder` will update the files relative to the workspace when `base_dir = ..` is uncommented. Otherwise, its context will be the eventual answers below the `====` separator, and the globs won't be taken into account.

## Licensing

All of these packs are licensed under MIT or Apache 2 for maximum flexibility and are, therefore, free to use as a base for creating your own.

## Contribution

Except for finding obvious bugs or typos, it's recommended that you open an issue to describe the scope before working on and submitting a PR for a feature enhancement.

<br />

[This GitHub Repo](https://github.com/aipack-ai/packs-pro)
