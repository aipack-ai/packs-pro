# Rust Documentation Strategy

## Documentation Layout

Keep source files concise and move module-level documentation to Markdown files.

```text
docs/
├── rustdoc/
│   ├── lib.md
│   ├── params/
│   │   ├── mod.md
│   │   └── schema.md
│   └── runtime/
│       └── mod.md
└── for-llm/
    ├── overview.md
    ├── architecture.md
    ├── concepts.md
    ├── project-map.md
    └── coding-conventions.md
```

### Purpose

- `docs/rustdoc/`: Human-facing documentation included into rustdoc.
- `docs/for-llm/`: Documentation optimized for AI agents and code generation.

The `for-llm` name explicitly means "documentation for LLMs", not "documentation about LLMs".


## Source Documentation

Keep only concise API documentation in Rust source:

```rust
/// Parameters accepted by a program.
pub trait Params {}
```

Attach larger documentation via `include_str!`:

```rust
// src/lib.rs
#![doc = include_str!("../docs/rustdoc/lib.md")]
```

```rust
// src/params/mod.rs
#![doc = include_str!("../../docs/rustdoc/params/mod.md")]
```

```rust
// src/params/schema.rs
#![doc = include_str!("../../docs/rustdoc/params/schema.md")]
```

## Directory Mapping

Mirror the source tree inside `docs/rustdoc`.

```text
src/foo/bar.rs
docs/rustdoc/foo/bar.md

src/foo/mod.rs
docs/rustdoc/foo/mod.md

src/lib.rs
docs/rustdoc/lib.md
```

Avoid flattened names such as:

```text
docs/rustdoc/foo-bar.md
docs/rustdoc/runtime-mod.md
```

Mirroring scales better and keeps paths predictable.

## Guiding Principles

1. Keep Rust source focused on code.
2. Keep only short API docs in source.
3. Store module guides in Markdown.
4. Mirror the source tree under `docs/rustdoc`.
5. Keep AI-oriented documentation under `docs/for-llm`.
6. Re-export derive macros through a `derive` module for ergonomics.
7. Prefer a separate `-derive` crate while only derive macros exist.
