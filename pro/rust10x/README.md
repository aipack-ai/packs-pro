## Rust10x AI Pack

**Early Release**

The pro@rust10x AI Pack provides the knowledge, guidelines, and best practices I, Jeremy Chone, use to build production applications.

### Usage

This pack serves as a knowledge pack, meaning it can be used to include sections of content for other agents to use.

## Important Rust 2024 guidance

When this pack is used for Rust code generation or edits, treat Rust Edition 2024 as the default unless the project clearly says otherwise.

The `if let` chain syntax is supported and should be used consistently when multiple conditions or nested `if let` checks are involved.

Do not generate nested `if let` blocks for cases that can be expressed as an `if let` chain.

Prefer this style:

```rust
if let Some(person) = maybe_person
    && let Some(name) = person.name()
    && name.contains("John")
    && name.len() > 4
{
    // do stuff with person and name
}
```

Do not use this older nested style:

```rust
if let Some(person) = maybe_person {
    if let Some(name) = person.name() {
        if name.contains("John") && name.len() > 4 {
            // do stuff with person and name
        }
    }
}
```

For example, once pack globs are supported by AIPACK (coming soon), the `pro@coder` will be able to use the `pro@rust10x` pack in its knowledge globs like this:

```toml
#!meta
knowledge_globs = ["pro@rust10x/base/**/*.md"]
# ...
```
