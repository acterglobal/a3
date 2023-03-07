+++
title = "Templates"

sort_by = "weight"
weight = 30
template = "docs/page.html"

[extra]
toc = true
top = true
+++

Acter-core allows itself to be programmed to create Acter spaces and models through a powerful template system.

## TOML & Jinja2

An acter template is a [TOML][toml]-file with a description what events should be created, where fields can be replaced using the [Jinja2][jinja2] template engine without any default escaping applied. This allows to write template where data can be inserted, replaced, altered but also auto-generated in relation to the user applying it, data they input or the time it is applied. For example, the following would generate a new `ActerSpace` for the given users, taking their display_name as part of the name and create a todo-list with an action item in it assigned to them:

```toml
version = "0.1"
name = "Example Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The user" }

[objects.task_1]
type = "task"
title = "Scroll through the news"
assignees = ["{{ main.user_id }}"]
"m.relates_to" = { event_id = "{{ start_list.id }}" }
utc_due = "{{ now().as_rfc3339 }}"
```

### Template Execution Context

Other than the overall metadata, each template contains two sections `[inputs]` and `[objects]`, where as `inputs` are supplied by the outside executing instance and `objects` list what should be created. Usually at least one `user` instance input is required as otherwise no action can be taken, and at least one object should be present, or nothing is to be done.

Both `inputs` and `objects` are tables, where the key is the name under which the resulting object can be accessed within the template's context afterwards. Especially objects are ordered and will be executed in the order found. As templates might require previously executed data (see the `start_list.id` in the example above), the templates will also only be executed once the items is reached, no pre-emptive template checking happens before. Neither are type checks of fields being done before the template rendering happened.

As all acter events happen by a user, within a space, these must be supplied for most objects or `is-default = true` must be set on their input or creation. Obviously only one default per type can be specified and if none is specified but needed for the creation of the specific type, the evaluation will abort when reaching that point.

## Template Format Reference

Currently only `version = "0.1.0"` is supported. This is a first temporary version, used for tests and in the internal formats. Note that `versions` follow SemVer and everything below `1.0` is considered experimental and its support might be dropped at any time.

### version

`String`. Must be `version = "0.1.0"`

### name

`String`. A nice display name to use in logging and when showing to users.

### inputs

`Table` of input values, where the `key` is the name the value will have in the template context once made available. Fields:

- `type` (either `user`, `space` or `text`, required): which type of input is this? a `user`, a `space` or just a `text`?
- `required` (`bool`, optional, default: `false`): defines whether execution can continue if this input is missing
- `description` (`String`, optional), gives a hint to the user what this field is used/needed for
- `is-default` (`bool`, optional, default: `false`): set this input as the default `user` or `space` for the execution of the template

### objects

`Table` of objects to create, where the `key` is the name the value will have in the template context once made available. The `type`-field defines, which object to create. Depending on the `type` different fields are available.

#### `object[type="space"]`

#### `object[type="task-list"]`

#### `object[type="task"]`

#### `object[type="pin"]`

## Functions & Filters

Aside from the minijinja builtin [functions](https://docs.rs/minijinja/latest/minijinja/functions/index.html#functions) & [filters](https://docs.rs/minijinja/latest/minijinja/filters/index.html#functions), we provide additional [functions](/api/main/rust/effektio_core/templates/functions.html) and [filters](/api/main/rust/effektio_core/templaets/filters.html). Check their API documentation for details.

[toml]: https://github.com/toml-lang/toml
[jinja2]: https://jinja.palletsprojects.com/en/3.1.x/templates/
