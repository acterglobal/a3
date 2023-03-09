+++
title = "Project Layout"

sort_by = "weight"
weight = 0
template = "docs/page.html"

[extra]
toc = false
top = false
+++

The third generation of Acter ("a3" or "A3") is a matrix-backed community organizing App for the regular joe. It has a mobile-first approach with support for desktop as well, supporting all major platforms (Apple iOS, Android, Windows, MacOSx & Linux).

Acter consist of two main parts

- the `core`, written in Rust (on the [matrix-rust-sdk](https://github.com/matrix-org/matrix-rust-sdk)) and compiled to the target architecture
- the end-user Application built with Flutter.
- and in between those two we have the glue that is the ffi-interface bridged through a flutter package into the app

## File structure

When looking at the repository, you will find the following folder structure:

```
app                      # The flutter app
├── android                    # - Android specific configuration
├── assets                     # - general assets
├── ..
├── integration_test           # - Full app integration tests
├── ios                        # - iOS specific configuration
├── lib                        # - the actual flutter App
├── linux                      # - Linux specific configuration
├── macos                      # - MacOS specific configuration
├── packages                   # - custom packages
│   └── rust_sdk                  # - the SDK package
├── test                       # - Flutter widget unit tests
├── web                        # - Web specific configuration (not yet support)
└── windows                    # - Windows specific configuration
docs                    # These documentation files
├── *
native                  # Rust native libraries
├── cli                        # Command-Line interface
├── core                       # Core types and inner system
├── effektio                   # FFI generation layer and public lib interface
├── effektio-test              # Rust integration tests
└── effektio-tui               # A terminal UI client
util                    # Further utilities
└── cucumber_reporter          # generating HTML reports from cucumber integration tests
└── ...
```

## Rust Core

The main logic takes place into the rust core library. Let's take a look at that:

```
native/core/src
├── client.rs                  # -- CoreClient main interface, binding it all together
├── error.rs                   # -- Core Error types
├── events                     # -- Matrix Event specific for our App
│   ├──  ...
├── events.rs
├── executor.rs                # -- The core state machine
├── lib.rs
├── models                     # -- The state machine models the events are applied on
│   ├──  ...
├── models.rs
├── spaces.rs                  # -- Anything related to Acter spaces
├── statics.rs                 # -- Some static strings and helpers
├── store.rs                   # -- Our internal storage interface (on top )
├── support.rs                 # -- Additional support structure
├── templates.rs               # -- the template engine logic
└── util.rs                    # -- further utilities
```
