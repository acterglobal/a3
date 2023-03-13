+++
title = "Acter Data Model"

sort_by = "weight"
weight = 1
template = "docs/page.html"

[extra]
toc = true
top = false
+++

Built on [Matrix](https://matrix.org) with end-to-end-encryption-based privacy on the forefront means Acter3 can't rely on any classic Relational- or Document-Database to manage the current state. Instead Acter builds upon the activity-stream nature of the matrix protocol by applying these events to a state machine upon models. Within this concept, an event may create a new Model or be applied to an existing model or both. Like task-event, which may create the task itself, but also alters the task-list it belongs to, or a comment event creating a comment related to a different object. Similarly, there are pure update events, which do not create models themselves but only transition the state of an existing model - like the TaskUpdate event for example.

## Linear timeline

For this system to work, updates must be applied in a linear fashion. Thus, when the application re-connects and finds new messages have been posted since it went offline, it must fetch these events from the last point it had until now and apply them in the order they have been sent.

## Permissive data merging

As the system is not CRDT conform, the order of events could matter. However, most "transitions" are pretty permissive in their nature, meaning that from a higher level perspective the order doesn't necessarily make much of a problem or is pretty easy to resolve or ignore. Take an update of a task for example, which two distinct entities have sent out as completed. While the applied order could matter internally, the last update wins and thus the history of the model shows two
updates that checked the task off. But what matters eventually from the end-user perspective is that the item has been checked off.

With this idea in mind, rather than using the regular `edit`-system matrix already uses for its chat messages, which replaces the entire content with a new content, Acter users distinct Update-Events, with only those fields included that are changed by that update. That unfortunately means that the server can not just calculate the latest version and sent that over the wire, but because the client needs to allow for more precise data-based internal control, wouldn't help much anyways.

All data models however, are having this exact idea in mind: it should be okay - for most cases - if just the latest update wins and not too much inner relationship should be assumed to be happening within the same update (as the order of in-between events could render that useless). Be permissive even if that might mean seeing the same event checked off twice, is fine.

## End user oriented

Our models and events are end-user oriented. That sometimes means we encapsulate more UI/UX information than other protocols might want to force on their implementations. We, however, mark everything as development until we have confirmed they work for the end-users in the way we expect them and to ensure consistency and avoid misinterpretation we thus encode all UI/UX information necessary, including what degree they have to be followed.

Further more, the event model itself, too, leads from a autonomous-user approach. As an example, to add users to a room, they are only invited rather than hard-added. At the same time, we need to balance that not everything needs the user to first find out about it themselves but instead lead them to good choices to be made. This, too, is ingrained in the modeling of events, their relationship and who can sent them when.

## Special Spaces

Because Acter needs to read the entire history upon joining to be able to calculate the accurate state of all models in the state machine client side, we do not mix the state machine data with linear chat messages, which reading from the newest backwards is just a fine support case. To signify that a space is of this special state machine, we've set its `purpose`-state as described in [MSC3088][] to our special [`acter purpose value`](/api/main/rust/acter_core/statics/static.PURPOSE_TEAM_VALUE.html). Only spaces with that purpose state will be read and assumed to be acter spaces with a state machine.

[msc3088]: https://github.com/matrix-org/matrix-spec-proposals/blob/travis/msc/mutable-subtypes/proposals/3088-room-subtyping.md
