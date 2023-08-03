+++
title = "Introduction"
sort_by = "weight"
weight = 1
template = "docs/page.html"
+++

## Welcome

Welcome to the Acter documentation for Administrators. This section contains information for space administrator, moderators as well as system administrators and technical and security consultants to dig deeper into acter and understand its underlying system.

## Introduction to Matrix

Acter is built upon the [publicly spec'ed][SPEC-PROCESS] decentralized [Matrix][matrix-org] instant messaging protocol. It's a http(s)-based REST protocol exchanging JSON between federated servers, and servers and clients. The Acter App is a client for that protocol.

This is a federated protocol similar to email, including that users are bound to a server that is identified via DNS and [embedded in the username][SPEC-user-id]. E.g. `@sari:acter.global` is the account of `sari` on the `acter.global` server.

## Understanding spaces, chats & rooms

Next to users and their profiles the most important entity in matrix are `rooms`. Almost everything happens within the context of some room: sending chat messages, configuring hierarchy, sharing files and state machines. Consider a room the base entity of shared permissions and access of a (changing) set of users.

Rooms can be configured to be of [various `types`][SPEC-types]. By default a room is considered a chat room for instant messaging (called a "chat" in acter context). By setting the `is_dm`-flag, it can be marked as being a direct message between a small set of people. Next to that the matrix spec knows of `spaces`, which are generally understood to be hierarchical rooms referencing other rooms and allowing for permission sharing.

Acter spaces are a [MSC3008][MSC3008] configured subtype with the [`global.acter.team`-purpose][CODE-purpose-static]. Any space can be set to become an acter space by setting its `purpose` to that and the Acter app will recognize it properly.

_Naming things_: As all entities - chat rooms, DMs and spaces - are the same `room` entity underneath, this admin section of the docs will primarily use the term "room" and only use space or "acter space" if it is about specific things only applicable to that area and not rooms in general.

### Space hierarchy

Spaces introduced hierarchical organization in the matrix protocol in a bi-directional pattern. Meaning that any space or room can configure any number of `space.parent` and `space.child` references in their own state pointing in either direction. This allows for a highly flexible reference and space association system. To clarify that a bit, we are using the following terms depending on the bi-directional states:

- Space or Room A has a `space.parent` reference to a space B with a `space.child` referencing Room A: Room A consider Space B its parent.
  (Allowing to have more than one associated parent allows us to have "joint venture"-spaces and rooms that cross the boundaries of any number of organizations)
- Space X has a `space.child` reference to a _space_ Y that has a `space.parent` referencing Space X: Space X considers the space Y a "subspace"
- Space P has a `space.child` reference to a _room_ Q that has a `space.parent` referencing Space P: Space P considers room Q a (space) "chat" (and is listed underneath it)
- Space M has a `space.child` reference to space K without knowing whether that has any relation to it (because it might be hidden to it or there is no references on it): Space M consider K a "recommended space" -- this is useful to show other spaces or organizations on your space to recommend to the viewer.

#### Space hierarchy permissions

Through this hierarchy room join permissions can also be configured to be in relation to these spaces. E.g. you can configure a room to allow anyone from its parent spaces to join.

## Learn more

- [Matrix Specification Process][SPEC-PROCESS]
- [Matrix User Identifies][SPEC-user-id]

[SPEC-user-id]: https://spec.matrix.org/v1.7/appendices/#user-identifiers
[SPEC-types]: https://spec.matrix.org/v1.7/client-server-api/#types
[matrix-org]: https://matrix.org
[SPEC-PROCESS]: https://github.com/matrix-org/matrix-spec-proposals#the-matrix-spec-process
[MSC3008]: https://github.com/matrix-org/matrix-spec-proposals/pull/3088
[CODE-purpose-static]: https://github.com/acterglobal/a3/blob/main/native/core/src/statics.rs#L6C40-L6C57
