import 'package:flutter/material.dart';

class EventsKeys {
  // Create new event
  static const eventNameTextField = Key('event-name-text-field');
  static const eventDescriptionTextField = Key('event-description-text-field');
  static const eventStartDate = Key('event-start-date');
  static const eventStartTime = Key('event-start-time');
  static const eventEndDate = Key('event-end-date');
  static const eventEndTime = Key('event-end-time');

  // Add event location
  static const eventLocationNameTextField = Key('event-location-name-text-field');
  static const eventLocationUrlTextField = Key('event-location-url-text-field');
  static const eventLocationAddressTextField = Key('event-location-address-text-field');
  static const eventLocationNoteTextField = Key('event-location-note-text-field');

  // Create and edit button for event
  static const eventCreateEditBtn = Key('event-create-edit-btn');

  // RSVP Keys
  static const eventRsvpGoingBtn = Key('event-rsvp-going-btn');
  static const eventRsvpNotGoingBtn = Key('event-rsvp-not-going-btn');
  static const eventRsvpMaybeBtn = Key('event-rsvp-maybe-btn');

  // Appbar action button
  static const appbarMenuActionBtn = Key('event-appbar-menu-action-btn');

  static const eventShareAction = Key('event-share-event');

  // Edit Event
  static const eventEditBtn = Key('event-edit-btn');

  // Delete Event
  static const eventDeleteBtn = Key('event-delete-btn');
  static const eventRemoveBtn = Key('event-remove-btn');
}
