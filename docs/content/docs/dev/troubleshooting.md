+++
title = "Troubleshooting"

weight = 10
template = "docs/page.html"

[extra]
toc = true
top = false
+++

Common problem when developing Acter and their solutions.

## `Unhandled Exception: failed to read or write to the crypto store the account in the store doesn't match the account in the constructor: expected ..:acter.global:guest_device, got ..:acter.global:guest_device

The App didn't successfully store the old token and when trying to start a fresh guest account, opening the crypto store failed. Until [#527](https://github.com/acterglobal/a3/issues/527) is fixed, you need to:

1. stop the app
2. clear the [user data](#where-is-the-user-data-stored)
3. start the app again

This should give you a fresh guest account login.

## Where is the user data stored?

We are using [`path_provider`'s `getApplicationDirectory`](https://pub.dev/packages/path_provider) to know where to store the user data. The exact folder the data is stored, is system dependent. These usually are:

- Linux: `~/.local/share/global.acter.app/` (e.g. `/home/ben/.local/share/global.acter.app/`)
- Windows: `$USERDIR\AppData\Roaming\global.acter\app` (e.g. `C:\Users\Ben\AppData\Roaming\global.acter\app`)
- MacOS: `$USER/Library/Containers/global.acter.app/` (e.g. `/Users/ben/Library/Containers/global.acter.app/`, notice that _Finder_ doesn't see the `Library` folder, you need to use the terminal to get there)

Just opening a terminal and doing `rm -rf $PATH` (where `$PATH` is the necessary path above), usually resets all locally stored data. **Careful as this also removes all locally held crypto tokens**.
