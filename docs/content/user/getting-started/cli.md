+++
title = "Command Line Interface"

sort_by = "weight"
weight = 20
template = "docs/page.html"
+++

In some situations, it might be useful to not start the full UI but use only a subset of the acter feature set. For this acter has a command line interface built in. This is only possible on desktop devices.

## Starting acter from the terminal

First you need to open a terminal. If you don't know how to do this, here are some step-by-step-guides for:

- [Windows](https://www.wikihow.com/Open-Terminal-in-Windows)
- [Mac](https://www.wikihow.com/Get-to-the-Command-Line-on-a-Mac)
- [Linux](https://www.wikihow.com/Run-a-Program-from-the-Command-Line-on-Linux)

Once you have a terminal, you can usually just drag and drop the acter-executable from whatever file explorer you are using into the terminal. It should add the path in the Terminal. On Mac this only shows the path to the package, you need to add `/Contents/MacOs/Acter` to get to the actual executable. To execute the command press `enter`. This should start the regular Acter App from the terminal giving you some helpful output that you can mark and copy-paste, for example to attach to issue reports.

Additionally, before starting the program by pressing `enter`, you can add various commands after an additional space (` `), that make acter start in a different way:

## Acter commands

By default, with no extra arguments given (arguments are separated by a space), acter will just load the regular UI and run the proper client. But given a command after the executable will put it into cli mode and it will attempt to do what you are asking from it.

### `--help` / `help [command]`

You can always start by just adding `--help` to your `acter` command. Even though we try to keep this page accurate and up-to-date, this is always the most accurate information about what your specific acter executable supports. So always check that first. To learn more about the options, flags and features of a particular command listed, use `help [command]` (where you replace `[command]` with the specific command in question, for e.g. `help info`) to get more information.

At the time of writing this is the output you'll see:

```
flutter: community communication and casual organizing platform

Usage: acter <command> [arguments]

Global options:
-h, --help    Print this usage information.

Available commands:
  backup-and-reset   Backup accounts and sessions and reset the state to fresh and clean
  info               Local info about your acter

Run "acter help <command>" for more information about a command.
```

### info

This command shows you various information about the app and your local data.

### backup-and-reset

Issue this command, if you want to reset your local state. This can be necessary if you can't start the app anymore for unknown reasons. This will create a backup of your session and all internal data (including encryption keys) before resetting.
