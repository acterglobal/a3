- By default all space app features are deactivated now and need to be explicitly activated at first. The activation, however, has become a lot easier by being provided through the actions on the bottom of each space: if the feature isn't active yet, the admin still sees the button and upon click is asked if they want to activate it, including the option to set the permission level of who can use that app.

- [Fix] where the app settings of previously created spaces where interpreted under the new defaults incorrectly. Instead we are keeping the old fallback and default behavior and the wire protocol as is and instead create all futures spaces with the explicit having the features turned off now.

- [Chat]: Now we have hardened the mentions matching in chat input text so it won't imply false positives and only validates user mentions belonging to rooms.


- Link Help Center from Settings page

- Rename process from app to acter in task manager on windows
- [New] : Time format is now based on the your localised system setting (12 Hour/24 Hour)
