+++
title = "Security"

sort_by = "weight"
weight = 20
template = "docs/page.html"
+++

## End-2-End Encrypted Chat

By default all Chats created with Acter are end-to-end-encrypted. That means only the participants of the chat can decrypted and read the messages. No server, routing proxy or entity that can intercept the message can do anything with them. This applies to Direct Messages as well as Group Chats created with the Acter App.

### Metadata

All events contain certain routing metadata required to allow the federated servers to give them to the right target. This includes the `senderId` (your `@userName:server.tld`) and the chat or space it belongs to (`roomId`) even in an encrypted message. Further more, all room state, like avatar, title and list of participants is visible for all participating servers.

#### Push Notifications

Push Notifications in the Matrix context only contain the local session-id, room-id and event-id. Out of that the client fetches the information and decrypts it if necessary for displaying. No relevant information is shared with Apple or Google.

## Encrypted-at-rest storage

Since the merge of [PR 945](https://github.com/acterglobal/a3/pull/945) (October 2023) all newly created sessions are encrypted-at-rest. That means we are storing all data locally in an encrypted fashion with a locally created, random encryption key that is stored in the operation systems secure enclave (also referred to as "keychain"). Even if your device is stolen or taken off you or its data copied, no one will be able to read messages and data received off of that data log unless you unlocked your device.

## Device verification

When you log in with Acter, as well as in the Activities-section of Acter itself, you might be prompted about "unverified sessions". This is a security measure to ensure only devices you use are logged in and no one else is attempting to spoof your identify and sneak into the system. It is highly recommended you cross-verify all devices of your account whenever you notice this coming up.

### Shared decryption secrets across verified devices

One important reason to verify devices is that, because encryption keys are only held on the end-devices, a new device is not able to read the history of messages before it logged on (you might know that from WhatsApp or Signal). If you verify that sessions with another device that has the encryption keys, they can share them upon request and thus smooth out the problem of a missing history.

## Are space encrypted?

As off now, spaces are not encrypted by default. While the plan is to make that the default, there are some challenges around shared history and ensuring consistency when messages can't be decrypted.
