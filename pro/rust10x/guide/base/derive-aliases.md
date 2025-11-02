## Derive Aliases Best Practices

If the user explicitly asks to use derive aliases, use the `macro_rules_attribute` crate and its `derive_alias!` declarative macro.

The rules below define how to wire it into a project.

### Dependency in Cargo.toml

Add `macro_rules_attribute = "0.2"` to Cargo.toml under the `# -- Others` section, right below `derive_more` if present.

### Module structure best practices

All derive aliases for a module layer live in a `derive_aliases.rs` file at that layer root. Import them in that layer's `mod` and make them available to submodules via `use derive_aliases::*;`.

For example, for the general/common derive aliases in the `main.rs` or `lib.rs` we will have

```rust
...
mod derive_aliases;

use derive_aliases::*; 
...
```

And then have the corresponding `derive_aliases.rs` in this folder.

This way, those aliases are available for any module below, but not public to parent modules. 

Now, if we have derive aliases only for some specific layer, for example, the `src/model/...`, then in the `src/model/mod.rs` we will have a similar pattern as above. 

### How to define a `derive_aliases.rs`

Here is a concise starting point for the root `derive_aliases.rs`

```rust
use macro_rules_attribute::derive_alias;

derive_alias! {
	// Basic compare (no float)
	#[derive(Cmp!)] = #[derive(PartialEq, Eq, PartialOrd, Ord)];

	// Basic hash (e.g., for hash keys)
	#[derive(Hash!)] = #[derive(PartialEq, Eq, Hash)];

    // For enum as str
	#[derive(EnumAsStr!)] = #[derive(strum::IntoStaticStr, strum::AsRefStr)];
}
```

The first two (Cmp, Hash) can be added by default, and the one about EnumAsStr only if `strum` is part of the Cargo.toml.

Now, some submodules might have their own `derive_aliases.rs`. While the goal is not to create one for each layer, for the key module layers that might be a good idea if the user asks. Some of those aliases will probably be compositions of the general aliases. 

For example, for a `src/model/derive_aliases.rs` we could have 

```rust
use macro_rules_attribute::derive_alias;

derive_alias! {
	#[derive(ScalarStruct!)] = #[derive(
		crate::Cmp!,
		Clone,
		Copy,
		Hash,
		derive_more::From,
		derive_more::Into,
		derive_more::Display,
		derive_more::Deref,
		modql::SqliteFromValue,
		modql::SqliteToValue
	)];
}
```

In this example, this is an alias for a simple tuple struct that wraps a primitive type. Adapt the list based on what the user wants. 

Note that we can use the `crate::Cmp!` that was defined, and even in the same `derive_alias!` we can use aliases defined earlier in the block. 

### Usage of the derive aliases

Use `macro_rules_attribute`'s `derive` proc macro. Keep it namespaced (short), for example `mra`.

For example: 

```rust
use macro_rules_attribute as mra;

#[mra::derive(
  Debug,
  crate::model::ScalarStruct!
)]
pub struct Id(i64);
```

### Important Consideration

Overlapping aliases.

If two aliases expand to any common derive traits, do not use them together. Choose the alias that covers the broader set, then add any missing derives explicitly.