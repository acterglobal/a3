+++
title = "Moderation"
sort_by = "weight"
weight = 25
template = "docs/page.html"
+++

## Power Levels

Permissions within any room (so a single chat or space) is configured through so called [PowerLevels in matrix][0]. A power level is a number, everyone in the room configured with a number higher or equal to the number is allowed to perform the action, everyone below is not. Canonically (if only values 0-100 are used) a user with the power level of 100 is called an "Administrator", 50 is equal to a "Moderator", 0 is a regular user.

The creator of a room (or both for a DM) is given power level 100 by default. Admins can configure the power level of each user, as well as change which power levels are required per specific action or feature as well as the default fallback for every user not assigned a specific power level.

## Room Moderation Actions

### Redact a message

_Default Power Level requirement:_ 50 (_Moderator_)

If any user code is offensive or otherwise against the terms of service or code of conduct of the associated space a moderator may _redact_ that message. This removes the user-generated content from the message, including any copies on the server. Some specific [metadata](/admin/security/metadata) is kept for technical reasons however.

### Kick a user

_Default Power Level requirement:_ 50 (_Moderator_)

If a user is spamming the room or otherwise doesn't adhere to the code of conduct or terms of service of the space, any moderator can kick the user (with a lower power level) from the space. This removes them from the space with a publicly stated message, and they have to rejoin actively before they can continue. Thus it is considered a pretty harsh warning and should usually not come out of the blue but only be issued after a warning has been stated before.

### Ban a user

_Default Power Level requirement:_ 50 (_Moderator_)

If you want to permanently block a user from even rejoining the space, a user can additionally be banned from the space/room. This write the username as blocked within the room state permanently. This can be revoked any time (but must be done manually at this point).

### Update Room Profile & power level requirements

_Default Power Level requirement:_ 100 (_Admin_)

Admins can update the room profile data, like display name, avatar and topic and any other room state fields, like the power level requirements for any action.

### Change a user's power level

_Default Power Level requirement:_ any

Any user can promote the power level of any other user up to the power level that user has. E.g. any Moderator with level 50 can promote any other user to also up to the power level of 50. They can only lower the power level for users that have a power level _lower than their own_. An admin can not demote another admin - only that admin can do that themselves (until [MSC3993][] has been adopted).

## Learn more

- [Matrix Spec section about Room Permissions][1], and [Power Levels][0]
- [MSC 3993: Room takeover][MSC3993]

[0]: https://spec.matrix.org/v1.7/client-server-api/#mroompower_levels
[1]: https://spec.matrix.org/v1.7/client-server-api/#permissions
[MSC3993]: https://github.com/matrix-org/matrix-spec-proposals/pull/3993
