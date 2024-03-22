
//   ######   ##        #######  ########     ###    ##          ######## ##    ##  ######  
//  ##    ##  ##       ##     ## ##     ##   ## ##   ##          ##       ###   ## ##    ## 
//  ##        ##       ##     ## ##     ##  ##   ##  ##          ##       ####  ## ##       
//  ##   #### ##       ##     ## ########  ##     ## ##          ######   ## ## ##  ######  
//  ##    ##  ##       ##     ## ##     ## ######### ##          ##       ##  ####       ## 
//  ##    ##  ##       ##     ## ##     ## ##     ## ##          ##       ##   ### ##    ## 
//   ######   ########  #######  ########  ##     ## ########    ##       ##    ##  ######  


/// Initialize logging
fn init_logging(log_dir: string, filter: string) -> Result<()>;

/// Set the global proxy to the given string. Will only apply to client initialized after calling this.
fn set_proxy(proxy: Option<string>);

/// Rotate the logging file
fn rotate_log_file() -> Result<string>;

/// Allow flutter to call logging on rust side
fn write_log(text: string, level: string) -> Result<()>;

/// Create a new client for homeserver at url with storage at data_path
fn login_new_client(base_path: string, media_cache_base_path: string, username: string, password: string, default_homeserver_name: string, default_homeserver_url: string, device_name: Option<string>) -> Future<Result<Client>>;

/// Create a new client from the restore token
fn login_with_token(base_path: string, restore_token: string) -> Future<Result<Client>>;

/// Create an anonymous client connecting to the homeserver
fn guest_client(base_path: string, media_cache_base_path: string, default_homeserver_name: string, default_homeserver_url: string, device_name: Option<string>) -> Future<Result<Client>>;

/// Create a new client from the registration token
fn register_with_token(base_path: string, media_cache_base_path: string, username: string, password: string, registration_token: string, default_homeserver_name: string, default_homeserver_url: string, device_name: string) -> Future<Result<Client>>;

/// destroy the local data of a session
fn destroy_local_data(base_path: string, media_cache_base_path: Option<string>, username: string, default_homeserver_name: string) -> Future<Result<bool>>;

fn duration_from_secs(secs: u64) -> EfkDuration;

fn parse_markdown(text: string) -> Option<string>;

/// create size object to be used for thumbnail download
fn new_thumb_size(width: u64, height: u64) -> Result<ThumbnailSize>;

/// create a colorize builder
fn new_colorize_builder(color: Option<u32>, background: Option<u32>) -> Result<ColorizeBuilder>;

/// create a task ref builder
/// target_id: event id of target
/// task_list: event id of task list
/// action: link/embed/embed-subscribe/embed-accept-assignment/embed-mark-done
fn new_task_ref_builder(target_id: string, room_id: Option<string>, task_list: string, action: Option<string>) -> Result<RefDetailsBuilder>;

/// create a task list ref builder
/// target_id: event id of target
/// action: link/embed/embed-subscribe
fn new_task_list_ref_builder(target_id: string, room_id: Option<string>, action: Option<string>) -> Result<RefDetailsBuilder>;

/// create a calendar event ref builder
/// target_id: event id of target
/// action: link/embed/embed-rsvp
fn new_calendar_event_ref_builder(target_id: string, room_id: Option<string>, action: Option<string>) -> Result<RefDetailsBuilder>;

/// create a link ref builder
fn new_link_ref_builder(title: string, uri: string) -> Result<RefDetailsBuilder>;

/// create object reference
/// position: top-left/top-middle/top-right/center-left/center-middle/center-right/bottom-left/bottom-middle/bottom-right
fn new_obj_ref_builder(position: Option<string>, reference: RefDetails) -> Result<ObjRefBuilder>;


//  ########  ########  #### ##     ## #### ######## #### ##     ## ########  ######  
//  ##     ## ##     ##  ##  ###   ###  ##     ##     ##  ##     ## ##       ##    ## 
//  ##     ## ##     ##  ##  #### ####  ##     ##     ##  ##     ## ##       ##       
//  ########  ########   ##  ## ### ##  ##     ##     ##  ##     ## ######    ######  
//  ##        ##   ##    ##  ##     ##  ##     ##     ##   ##   ##  ##             ## 
//  ##        ##    ##   ##  ##     ##  ##     ##     ##    ## ##   ##       ##    ## 
//  ##        ##     ## #### ##     ## ####    ##    ####    ###    ########  ######  


/// Representing a time frame
object EfkDuration {}

object UtcDateTime {
    fn timestamp() -> i64;
    fn to_rfc2822() -> string;
    fn to_rfc3339() -> string;
    fn timestamp_millis() -> i64;
}

object RefDetails {
    /// the target id
    fn target_id_str() -> Option<string>;
    /// if that is in a different room, specified here
    fn room_id_str() -> Option<string>;
    /// gives either `link`, `task`, `task-list` or `calendar_client`
    fn type_str() -> string;
    /// what type of embed action is requested_inputs
    fn embed_action_str() -> string;
    /// if this is a `task` type, what `task-list-id` does it belong to
    fn task_list_id_str() -> Option<string>;
    /// if ref is `link`, its display title
    fn title() -> Option<string>;
    /// if ref is `link`, its uri
    fn uri() -> Option<string>;
}

/// An acter internal link to a different object
object ObjRef {
    /// where to position the element (if given)
    fn position_str() -> Option<string>;
    /// further details of the reference
    fn ref_details() -> RefDetails;
}

/// A builder for ObjRef
object ObjRefBuilder {
    /// set position of element
    /// position: top-left/top-middle/top-right/center-left/center-middle/center-right/bottom-left/bottom-middle/bottom-right
    fn position(position: string);
    /// empty position of element
    fn unset_position();

    /// change ref details
    fn reference(reference: RefDetails);

    fn build() -> ObjRef;
}

/// A foreground and background color setting
object Colorize {
    /// Foreground or text color
    fn color() -> Option<u32>;
    /// Background color
    fn background() -> Option<u32>;
}

/// A builder for Colorize. Allowing you to set (foreground) color and background
object ColorizeBuilder {
    /// RGBA color representation as int for the foreground color
    fn color(color: u32);
    /// unset the color
    fn unset_color();

    /// RGBA color representation as int for the background color
    fn background(color: u32);
    /// unset the background color
    fn unset_background();
}

/// A builder for RefDetails
object RefDetailsBuilder {
    /// it is valid for Task/TaskList/CalendarEvent ref
    /// target_id: event id of target
    fn target_id(target_id: string);

    /// it is valid for Task/TaskList/CalendarEvent ref
    fn room_id(room_id: string);
    /// unset the room id, it is optional field
    fn unset_room_id();

    /// it is valid for Task/TaskList/CalendarEvent ref
    /// task_list: event id of task list
    fn task_list(task_list: string);

    /// it is valid for Task/TaskList/CalendarEvent ref
    /// action is one of TaskAction/TaskListAction/CalendarEventAction
    fn action(action: string);
    /// unset the action, it is optional field
    fn unset_action();

    /// it is valid for Link ref
    fn title(title: string);

    /// it is valid for Link ref
    fn uri(uri: string);

    fn build() -> RefDetails;
}

// enum LocationType {
//    Physical,
//    Virtual
// }

// object Location {
//    /// "physical" or "virtual"
//    fn location_type() -> string;
//    fn name() -> Option<string>;
//    fn description() -> Option<TextMessageContent>;
//    fn coordinates() -> Option<string>;
//    fn uri() -> Option<string>;
// }



//  ########     ###     ######  ####  ######     ######## ##    ## ########  ########  ######  
//  ##     ##   ## ##   ##    ##  ##  ##    ##       ##     ##  ##  ##     ## ##       ##    ## 
//  ##     ##  ##   ##  ##        ##  ##             ##      ####   ##     ## ##       ##       
//  ########  ##     ##  ######   ##  ##             ##       ##    ########  ######    ######  
//  ##     ## #########       ##  ##  ##             ##       ##    ##        ##             ## 
//  ##     ## ##     ## ##    ##  ##  ##    ##       ##       ##    ##        ##       ##    ## 
//  ########  ##     ##  ######  ####  ######        ##       ##    ##        ########  ######  



object OptionString {
    /// get text
    fn text() -> Option<string>;
}

object OptionBuffer {
    /// get data
    fn data() -> Option<buffer<u8>>;
}

object OptionRsvpStatus {
    /// get status
    fn status() -> Option<RsvpStatus>;

    /// get status in string
    fn status_str() -> Option<string>;
}

object UserProfile {
    /// get user id
    fn user_id() -> UserId;

    /// whether to have avatar
    fn has_avatar() -> bool;

    /// get the binary data of avatar
    /// if thumb size is given, avatar thumbnail is returned
    /// if thumb size is not given, avatar file is returned
    fn get_avatar(thumb_size: Option<ThumbnailSize>) -> Future<Result<OptionBuffer>>;

    /// get the display name
    fn get_display_name() -> Option<string>;
}

object RoomProfile {
    /// whether to have avatar
    fn has_avatar() -> bool;

    /// get the binary data of avatar
    /// if thumb size is given, avatar thumbnail is returned
    /// if thumb size is not given, avatar file is returned
    fn get_avatar(thumb_size: Option<ThumbnailSize>) -> Future<Result<OptionBuffer>>;

    /// get the display name
    fn get_display_name() -> Future<Result<OptionString>>;
}


/// Deliver receipt event from rust to flutter
object ReceiptEvent {
    /// Get transaction id or flow id
    fn room_id() -> RoomId;

    /// Get records
    fn receipt_records() -> Vec<ReceiptRecord>;
}

/// ReceiptThread wrapper
object ReceiptThread {
    /// whether receipt thread is Main
    fn is_main() -> bool;

    /// whether receipt thread is Unthreaded
    fn is_unthreaded() -> bool;

    /// Get event id for receipt thread that is neither Main nor Unthreaded
    fn thread_id() -> Option<EventId>;
}

/// Deliver receipt record from rust to flutter
object ReceiptRecord {
    /// Get id of event that this user read message from peer
    fn event_id() -> string;

    /// Get id of user that read this message
    fn seen_by() -> string;

    /// Get time that this user read message from peer in milliseconds
    fn timestamp() -> Option<u64>;

    /// Get the receipt type, one of m.read or m.read.private
    fn receipt_type() -> string;

    /// Get the receipt thread wrapper
    fn receipt_thread() -> ReceiptThread;
}

/// Deliver typing event from rust to flutter
object TypingEvent {
    /// Get transaction id or flow id
    fn room_id() -> RoomId;

    /// Get list of user id
    fn user_ids() -> Vec<UserId>;
} 

object TextMessageContent {
    fn body() -> string;
    fn formatted() -> Option<string>;
}

object MediaSource {
    fn url() -> string;
}

object ThumbnailInfo {
    /// thumbnail mimetype
    fn mimetype() -> Option<string>;
    /// thumbnail size
    fn size() -> Option<u64>;
    /// thumbnail width
    fn width() -> Option<u64>;
    /// thumbnail height
    fn height() -> Option<u64>;
}

object ThumbnailSize {}

object DeviceId {
    fn to_string() -> string;
}

object EventId {
    fn to_string() -> string;
}

object MxcUri {
    fn to_string() -> string;
}

object RoomId {
    fn to_string() -> string;
}

object UserId {
    fn to_string() -> string;
}



//  ##     ## ########  ########     ###    ######## ########  ######  
//  ##     ## ##     ## ##     ##   ## ##      ##    ##       ##    ## 
//  ##     ## ##     ## ##     ##  ##   ##     ##    ##       ##       
//  ##     ## ########  ##     ## ##     ##    ##    ######    ######  
//  ##     ## ##        ##     ## #########    ##    ##             ## 
//  ##     ## ##        ##     ## ##     ##    ##    ##       ##    ## 
//   #######  ##        ########  ##     ##    ##    ########  ######  



/// A single Slide of a NewsEntry
object NewsSlide {
    /// the content of this slide
    fn type_str() -> string;

    /// the unique, predictable ID for this slide
    fn unique_id() -> string;

    /// the references linked in this slide
    fn references() -> Vec<ObjRef>;

    /// The color setting
    fn colors() -> Option<Colorize>;

    /// if this is a media, hand over the description
    fn msg_content() -> MsgContent;
    /// if this is a media, hand over the data
    /// if thumb size is given, media thumbnail is returned
    /// if thumb size is not given, media file is returned
    fn source_binary(thumb_size: Option<ThumbnailSize>) -> Future<Result<buffer<u8>>>;
}

object NewsSlideDraft {
    /// add reference for this slide draft
    fn add_reference(reference: ObjRef);

    /// set the color according to the colorize builder
    fn color(color: ColorizeBuilder);

    /// unset references for this slide draft
    fn unset_references();
}

/// A news entry
object NewsEntry {
    /// the slides count in this news item
    fn slides_count() -> u8;
    /// The slides belonging to this news item
    fn get_slide(pos: u8) -> Option<NewsSlide>;
    /// get all slides of this news item
    fn slides() -> Vec<NewsSlide>;

    /// get room id
    fn room_id() -> RoomId;

    /// get sender id
    fn sender() -> UserId;

    /// get event id
    fn event_id() -> EventId;

    /// get the reaction manager
    fn reactions() -> Future<Result<ReactionManager>>;

    /// get the comment manager
    fn comments() -> Future<Result<CommentsManager>>;
}

object NewsEntryDraft {
    /// create news slide draft
    fn add_slide(base_draft: NewsSlideDraft) -> Future<Result<bool>>;

    /// change position of slides draft of this news entry
    fn swap_slides(from: u8, to:u8);

    /// get a copy of the news slide set for this news entry draft
    fn slides() -> Vec<NewsSlideDraft>;

    /// clear slides
    fn unset_slides();

    /// create this news entry
    fn send() -> Future<Result<EventId>>;
}

object NewsEntryUpdateBuilder {
    /// set the slides for this news entry
    fn add_slide(draft: NewsSlideDraft) -> Future<Result<bool>>;

    /// reset slides for this news entry
    fn unset_slides();
    fn unset_slides_update();

    /// set position of slides for this news entry
    fn swap_slides(from: u8, to: u8);

    /// update this news entry
    fn send() -> Future<Result<EventId>>;
}


//  ########  #### ##    ##  ######  
//  ##     ##  ##  ###   ## ##    ## 
//  ##     ##  ##  ####  ## ##       
//  ########   ##  ## ## ##  ######  
//  ##         ##  ##  ####       ## 
//  ##         ##  ##   ### ##    ## 
//  ##        #### ##    ##  ######  



/// Draft a Pin
object PinDraft {
    /// set the title for this pin
    fn title(title: string);

    /// set the content for this pin
    fn content_text(text: string);
    /// set the content of the pin through markdown
    fn content_markdown(text: string);
    /// set the content of the pin through html
    fn content_html(text: string, html: string);
    fn unset_content();

    /// set the url for this pin
    fn url(text: string);
    fn unset_url();

    /// fire this pin over - the event_id is the confirmation from the server.
    fn send() -> Future<Result<EventId>>;
}

/// A pin object
object ActerPin {
    /// get the title of the pin
    fn title() -> string;
    /// get the content_text of the pin
    fn content() -> Option<MsgContent>;
    /// get the formatted content of the pin
    fn content_formatted() -> Option<string>;
    /// Whether the inner text is coming as formatted
    fn has_formatted_text() -> bool;
    /// whether this pin is a link
    fn is_link() -> bool;
    /// get the link content
    fn url() -> Option<string>;
    /// get the link color settings
    fn color() -> Option<u32>;
    /// The room this Pin belongs to
    //fn team() -> Room;

    /// the unique event ID
    //fn event_id() -> EventId;
    fn event_id_str() -> string;
    /// the room/space this item belongs to
    fn room_id_str() -> string;

    /// sender id
    fn sender() -> UserId;

    /// make a builder for updating the pin
    fn update_builder() -> Result<PinUpdateBuilder>;

    /// get informed about changes to this pin
    fn subscribe_stream() -> Stream<bool>;

    /// replace the current pin with one with the latest state
    fn refresh() -> Future<Result<ActerPin>>;

    /// get the comments manager for this pin
    fn comments() -> Future<Result<CommentsManager>>;

    /// get the attachments manager for this pin
    fn attachments() -> Future<Result<AttachmentsManager>>;
}

object PinUpdateBuilder {
    /// set the title for this pin
    fn title(title: string);
    fn unset_title_update();

    /// set the content for this pin
    fn content_text(text: string);
    fn content_markdown(text: string);
    fn content_html(text: string, html: string);
    fn unset_content();
    fn unset_content_update();

    /// set the url for this pin
    fn url(text: string);
    fn unset_url();
    fn unset_url_update();

    /// fire this update over - the event_id is the confirmation from the server.
    fn send() -> Future<Result<EventId>>;
}

//   ######     ###    ##       ######## ##    ## ########     ###    ########  
//  ##    ##   ## ##   ##       ##       ###   ## ##     ##   ## ##   ##     ## 
//  ##        ##   ##  ##       ##       ####  ## ##     ##  ##   ##  ##     ## 
//  ##       ##     ## ##       ######   ## ## ## ##     ## ##     ## ########  
//  ##       ######### ##       ##       ##  #### ##     ## ######### ##   ##   
//  ##    ## ##     ## ##       ##       ##   ### ##     ## ##     ## ##    ##  
//   ######  ##     ## ######## ######## ##    ## ########  ##     ## ##     ## 



object CalendarEvent {
    /// the title of the event
    fn title() -> string;
    /// description text
    fn description() -> Option<TextMessageContent>;
    /// When the event starts
    fn utc_start() -> UtcDateTime;
    /// When the event ends
    fn utc_end() -> UtcDateTime;
    /// whether to show the time or just the dates
    fn show_without_time() -> bool;
    /// locations
    // fn locations() -> Vec<Location>;
    /// event id
    fn event_id() -> EventId;
    /// room id
    fn room_id_str() -> string;
    /// sender id
    fn sender() -> UserId;
    /// update builder
    fn update_builder() -> Result<CalendarEventUpdateBuilder>;
    /// get RSVP manager
    fn rsvps() -> Future<Result<RsvpManager>>;
    /// get the reaction manager
    fn reactions() -> Future<Result<ReactionManager>>;
    /// get my RSVP status, one of Yes/Maybe/No or None
    fn responded_by_me() -> Future<Result<OptionRsvpStatus>>;
    /// get the user id list who have responded with `Yes` on this event
    fn participants() -> Future<Result<Vec<string>>>;
}

object CalendarEventUpdateBuilder {
    /// set title of the event>
    fn title(title: string);

    /// set description text
    fn description_text(body: string);

    /// set description html text
    fn description_html(body: string, html_body: string);

    /// set utc start in rfc3339 string
    fn utc_start_from_rfc3339(utc_start: string) -> Result<()>;
    /// set utc start in rfc2822 string
    fn utc_start_from_rfc2822(utc_start: string) -> Result<()>;
    /// set utc start in custom format
    fn utc_start_from_format(utc_start: string, format: string) -> Result<()>;

    /// set utc end in rfc3339 string
    fn utc_end_from_rfc3339(utc_end: string) -> Result<()>;
    /// set utc end in rfc2822 string
    fn utc_end_from_rfc2822(utc_end: string) -> Result<()>;
    /// set utc end in custom format
    fn utc_end_from_format(utc_end: string, format: string) -> Result<()>;

    /// send builder update
    fn send() -> Future<Result<EventId>>;
}

object CalendarEventDraft {
    /// set the title for this calendar event
    fn title(title: string);

    /// set the description for this calendar event
    fn description_text(text: string);

    /// set the description html for this calendar event
    fn description_html(text: string, html: string);
    
    fn unset_description();

    /// set the utc_start for this calendar event in rfc3339 format
    fn utc_start_from_rfc3339(utc_start: string) -> Result<()>;
    /// set the utc_start for this calendar event in rfc2822 format
    fn utc_start_from_rfc2822(utc_start: string) -> Result<()>;
    /// set the utc_start for this calendar event in custom format
    fn utc_start_from_format(utc_start: string, format: string) -> Result<()>;

    /// set the utc_end for this calendar event in rfc3339 format
    fn utc_end_from_rfc3339(utc_end: string) -> Result<()>;
    /// set the utc_end for this calendar event in rfc2822 format
    fn utc_end_from_rfc2822(utc_end: string) -> Result<()>;
    /// set the utc_end for this calendar event in custom format
    fn utc_end_from_format(utc_end: string, format: string) -> Result<()>;

    /// create this calendar event
    fn send() -> Future<Result<EventId>>;
}


//  ########   ######  ##     ## ########  
//  ##     ## ##    ## ##     ## ##     ## 
//  ##     ## ##       ##     ## ##     ## 
//  ########   ######  ##     ## ########  
//  ##   ##         ##  ##   ##  ##        
//  ##    ##  ##    ##   ## ##   ##        
//  ##     ##  ######     ###    ##        



enum RsvpStatus {
    Yes,
    Maybe,
    No
}

object RsvpManager {
    /// whether manager has rsvp entries
    fn has_rsvp_entries() -> bool;

    /// get total rsvp count
    fn total_rsvp_count() -> u32;

    /// get rsvp entries
    fn rsvp_entries() -> Future<Result<Vec<Rsvp>>>;

    /// get Yes/Maybe/No or None for the user's own status
    fn responded_by_me() -> Future<Result<OptionRsvpStatus>>;

    /// get the count of Yes/Maybe/No
    fn count_at_status(status: string) -> Future<Result<u32>>;

    /// get the user-ids that have responded for Yes/Maybe/No
    fn users_at_status(status: string) -> Future<Result<Vec<UserId>>>;

    /// create rsvp draft
    fn rsvp_draft() -> Result<RsvpDraft>;

    /// get informed about changes to this manager
    fn subscribe_stream() -> Stream<bool>;
}

object RsvpDraft {
    /// set status of this RSVP
    fn status(status: string);

    /// create this RSVP
    fn send() -> Future<Result<EventId>>;
}

object Rsvp {
    /// get sender of this rsvp
    fn sender() -> UserId;

    /// get timestamp of this rsvp
    fn origin_server_ts() -> u64;

    /// get status of this rsvp
    fn status() -> string;
}

//  ### ##   ### ###    ##      ## ##   #### ##    ####    ## ##   ###  ##   ## ##   
//  ##  ##   ##  ##     ##    ##   ##  # ## ##     ##    ##   ##    ## ##  ##   ##  
//  ##  ##   ##       ## ##   ##         ##        ##    ##   ##   # ## #  ####     
//  ## ##    ## ##    ##  ##  ##         ##        ##    ##   ##   ## ##    #####   
//  ## ##    ##       ## ###  ##         ##        ##    ##   ##   ##  ##      ###  
//  ##  ##   ##  ##   ##  ##  ##   ##    ##        ##    ##   ##   ##  ##  ##   ##  
// #### ##  ### ###  ###  ##   ## ##    ####      ####    ## ##   ###  ##   ## ## 


object ReactionManager {

    /// get count sent like by me and other people
    fn likes_count() -> u32;

    /// whether I sent like
    fn liked_by_me() -> bool;

    /// whether I reacted using symbol key
    fn reacted_by_me() -> bool;

    /// whether manager has reaction entries
    fn has_reaction_entries() -> bool;

    /// get total count of reactions
    fn total_reaction_count() -> u32;

    /// get reaction entries
    fn reaction_entries() -> Future<Result<Vec<Reaction>>>;

    /// send a like
    fn send_like() -> Future<Result<EventId>>;

    /// send the reaction using symbol key
    fn send_reaction(key: string) -> Future<Result<EventId>>;

    /// remove the like
    fn redact_like(reason: Option<string>, txn_id: Option<string>) -> Future<Result<EventId>>;

    /// get informed about changes to this manager
    fn subscribe_stream() -> Stream<bool>;

    /// get informed about changes to this manager
    fn reload() -> Future<Result<ReactionManager>>;
}

object Reaction {

    /// event id of reaction event
    fn event_id_str() -> string;

    /// get sender of this reaction
    fn sender() -> UserId;

    /// get timestamp of this reaction
    fn origin_server_ts() -> u64;

    /// the event id to which it is reacted
    fn relates_to() -> string;
}


//  ########   #######   #######  ##     ##    ######## ##     ## ######## ##    ## ########  ######  
//  ##     ## ##     ## ##     ## ###   ###    ##       ##     ## ##       ###   ##    ##    ##    ## 
//  ##     ## ##     ## ##     ## #### ####    ##       ##     ## ##       ####  ##    ##    ##       
//  ########  ##     ## ##     ## ## ### ##    ######   ##     ## ######   ## ## ##    ##     ######  
//  ##   ##   ##     ## ##     ## ##     ##    ##        ##   ##  ##       ##  ####    ##          ## 
//  ##    ##  ##     ## ##     ## ##     ##    ##         ## ##   ##       ##   ###    ##    ##    ## 
//  ##     ##  #######   #######  ##     ##    ########    ###    ######## ##    ##    ##     ######  

/// Sending state of outgoing message.
object EventSendState {
    // one of NotSentYet/SendingFailed/Cancelled/Sent
    fn state() -> string;
    
    // gives error value for SendingFailed only
    fn error() -> Option<string>;

    // gives event id for Sent only
    fn event_id() -> Option<EventId>;
}

/// A room Message metadata and content
object RoomEventItem {
    /// Unique ID of this event
    fn unique_id() -> string;

    /// The User, who sent that event
    fn sender() -> string;

    /// Send state of the message to server
    /// valid only when initialized from timeline event item
    fn send_state() -> Option<EventSendState>;

    /// the server receiving timestamp in milliseconds
    fn origin_server_ts() -> u64;

    /// one of Message/Redaction/UnableToDecrypt/FailedToParseMessageLike/FailedToParseState
    fn event_type() -> string;

    /// the type of massage, like text, image, audio, video, file etc
    fn msg_type() -> Option<string>;

    /// covers text/image/audio/video/file/location/emote/sticker
    fn msg_content() -> Option<MsgContent>;

    /// original event id, if this msg is reply to another msg
    fn in_reply_to() -> Option<string>;

    /// the list of users that read this message
    fn read_users() -> Vec<string>;

    /// the details that users read this message
    fn receipt_ts(user_id: string) -> Option<u64>;

    /// the emote key list that users reacted about this message
    fn reaction_keys() -> Vec<string>;

    /// the details that users reacted using this emote key in this message
    fn reaction_records(key: string) -> Option<Vec<ReactionRecord>>;

    /// Whether current user wrote this message and can modify it
    fn is_editable() -> bool;

    /// Whether this message was modified by author
    fn was_edited() -> bool;
}

object RoomVirtualItem {
    /// DayDivider or ReadMarker
    fn event_type() -> string;

    /// contains description text
    fn desc() -> Option<string>;
}

/// A room Message metadata and content
object RoomMessage {
    /// one of event/virtual
    fn item_type() -> string;

    /// valid only if item_type is "event"
    fn event_item() -> Option<RoomEventItem>;

    /// valid only if item_type is "virtual"
    fn virtual_item() -> Option<RoomVirtualItem>;
}

object MsgContent {
    /// available always
    fn body() -> string;

    /// available for text msg
    fn formatted_body() -> Option<string>;

    /// available for image/audio/video/file msg
    fn source() -> Option<MediaSource>;

    /// available for image/audio/video/file msg
    fn mimetype() -> Option<string>;

    /// available for image/audio/video/file msg
    fn size() -> Option<u64>;

    /// available for image/video msg
    fn width() -> Option<u64>;

    /// available for image/video msg
    fn height() -> Option<u64>;

    /// available for image/video/file/location msg
    fn thumbnail_source() -> Option<MediaSource>;

    /// available for image/video/file/location msg
    fn thumbnail_info() -> Option<ThumbnailInfo>;

    /// available for audio/video msg
    fn duration() -> Option<u64>;

    /// available for image/video msg
    fn blurhash() -> Option<string>;

    /// available for file msg
    fn filename() -> Option<string>;

    /// available for location msg
    fn geo_uri() -> Option<string>;
}

object ReactionRecord {
    /// who sent reaction
    fn sender_id() -> UserId;

    /// when reaction was sent
    fn timestamp() -> u64;

    /// whether I am the sender of this reaction
    fn sent_by_me() -> bool;
}

object RoomMessageDiff {
    /// Append/Insert/Set/Remove/PushBack/PushFront/PopBack/PopFront/Clear/Reset
    fn action() -> string;

    /// for Append/Reset
    fn values() -> Option<Vec<RoomMessage>>;

    /// for Insert/Set/Remove
    fn index() -> Option<usize>;

    /// for Insert/Set/PushBack/PushFront
    fn value() -> Option<RoomMessage>;
}

// enum RoomNotificationMode {
//    all,
//    mentions,
//    mute
// }

/// Rotate the logging file
fn new_join_rule_builder() -> JoinRuleBuilder;

object JoinRuleBuilder {
    fn join_rule(input: string);
    fn add_room(room: string);
}

//  ########   #######   #######  ##     ## 
//  ##     ## ##     ## ##     ## ###   ### 
//  ##     ## ##     ## ##     ## #### #### 
//  ########  ##     ## ##     ## ## ### ## 
//  ##   ##   ##     ## ##     ## ##     ## 
//  ##    ##  ##     ## ##     ## ##     ## 
//  ##     ##  #######   #######  ##     ## 


/// Generic Room Properties
object Room {
    /// the RoomId as a String
    fn room_id_str() -> string;

    /// the JoinRule as a String
    fn join_rule_str() -> string;

    /// if set to restricted or restricted_knock the rooms this is restricted to
    fn restricted_room_ids_str() -> Vec<string>;

    /// set the join rule.
    fn set_join_rule(join_rule_builder: JoinRuleBuilder) -> Future<Result<bool>>;

    /// whether we are part of this room
    fn is_joined() -> bool;

    /// get the room profile that contains avatar and display name
    fn get_profile() -> RoomProfile;

    /// get the room profile that contains avatar and display name
    fn space_relations() -> Future<Result<SpaceRelations>>;

    /// Whether this is a space (or, if this returns `false`, consider it a chat)
    fn is_space() -> bool;

    /// add the following as a parent room and return event id of that event
    /// room can have multiple parents
    fn add_parent_room(room_id: string, canonical: bool) -> Future<Result<string>>;

    /// remove a parent room
    fn remove_parent_room(room_id: string, reason: Option<string>) -> Future<Result<bool>>;

    /// the Membership of myself
    fn get_my_membership() -> Future<Result<Member>>;

    /// the members currently in the room
    fn active_members_ids() -> Future<Result<Vec<string>>>;

    /// the members currently in the room
    fn active_members() -> Future<Result<Vec<Member>>>;

    /// the members invited to this room
    fn invited_members() -> Future<Result<Vec<Member>>>;

    /// get the room member by user id
    fn get_member(user_id: string) -> Future<Result<Member>>;

    /// invite the new user to this room
    fn invite_user(user_id: string) -> Future<Result<bool>>;

    /// RoomNotificationMode for this room
    fn notification_mode() -> Future<Result<string>>;

    /// default RoomNotificationMode for this type of room
    fn default_notification_mode() -> Future<string>;

    /// Unset the `mute` for this room.
    fn unmute() -> Future<Result<bool>>;
    
    /// set the RoomNotificationMode
    fn set_notification_mode(new_mode: Option<string>) -> Future<Result<bool>>; 

    /// update the power levels of specified member
    fn update_power_level(user_id: string, level: i32) -> Future<Result<EventId>>;

}


object ConvoDiff {
    /// Append/Insert/Set/Remove/PushBack/PushFront/PopBack/PopFront/Clear/Reset
    fn action() -> string;

    /// for Append/Reset
    fn values() -> Option<Vec<Convo>>;

    /// for Insert/Set/Remove
    fn index() -> Option<usize>;

    /// for Insert/Set/PushBack/PushFront
    fn value() -> Option<Convo>;
}

object SpaceDiff {
    /// Append/Insert/Set/Remove/PushBack/PushFront/PopBack/PopFront/Clear/Reset
    fn action() -> string;

    /// for Append/Reset
    fn values() -> Option<Vec<Space>>;

    /// for Insert/Set/Remove
    fn index() -> Option<usize>;

    /// for Insert/Set/PushBack/PushFront
    fn value() -> Option<Space>;
}

object MsgContentDraft {
    /// available for only image/audio/video/file
    fn size(value: u64) -> MsgContentDraft;

    /// available for only image/video
    fn width(value: u64) -> MsgContentDraft;

    /// available for only image/video
    fn height(value: u64) -> MsgContentDraft;

    /// available for only audio/video
    fn duration(value: u64) -> MsgContentDraft;

    /// available for only image/video
    fn blurhash(value: string) -> MsgContentDraft;

    /// available for only file
    fn filename(value: string) -> MsgContentDraft;

    /// available for only location
    fn geo_uri(value: string) -> MsgContentDraft;

    // convert this into a NewsSlideDraft;
    fn into_news_slide_draft() -> NewsSlideDraft;
}

/// Timeline with Room Events
object TimelineStream {
    /// Fires whenever new diff found
    fn messages_stream() -> Stream<RoomMessageDiff>;

    /// get the specific message identified by the event_id
    fn get_message(event_id: string) -> Future<Result<RoomMessage>>;

    /// Get the next count messages backwards, and return whether it has more items
    fn paginate_backwards(count: u16) -> Future<Result<bool>>;

    /// send message using draft
    fn send_message(draft: MsgContentDraft) -> Future<Result<bool>>;

    /// modify message using draft
    fn edit_message(event_id: string, draft: MsgContentDraft) -> Future<Result<bool>>;

    /// send reply to event
    fn reply_message(event_id: string, draft: MsgContentDraft) -> Future<Result<bool>>;

    /// send single receipt
    /// receipt_type: FullyRead | Read | ReadPrivate
    /// thread: Main | Unthreaded
    fn send_single_receipt(receipt_type: string, thread: string, event_id: string) -> Future<Result<bool>>;

    /// send 3 types of receipts at once
    /// full_read: optional event id
    /// public_read_receipt: optional event id
    /// private_read_receipt: optional event id
    fn send_multiple_receipts(full_read: Option<string>, public_read_receipt: Option<string>, private_read_receipt: Option<string>) -> Future<Result<bool>>;

    /// send reaction to event
    /// if sent twice, reaction is redacted
    fn toggle_reaction(event_id: string, key: string) -> Future<Result<bool>>;

    /// retry local echo message send
    fn retry_send(txn_id: string) -> Future<Result<bool>>;

    /// cancel local echo message
    fn cancel_send(txn_id: string) -> Future<Result<bool>>;
}


//   ######   #######  ##    ## ##     ##  #######  
//  ##    ## ##     ## ###   ## ##     ## ##     ## 
//  ##       ##     ## ####  ## ##     ## ##     ## 
//  ##       ##     ## ## ## ## ##     ## ##     ## 
//  ##       ##     ## ##  ####  ##   ##  ##     ## 
//  ##    ## ##     ## ##   ###   ## ##   ##     ## 
//   ######   #######  ##    ##    ###     #######  



object Convo {
    /// get the room profile that contains avatar and display name
    fn get_profile() -> RoomProfile;

    /// get the room profile that contains avatar and display name
    fn space_relations() -> Future<Result<SpaceRelations>>;

    /// Change the avatar of the room
    fn upload_avatar(uri: string) -> Future<Result<MxcUri>>;

    /// Remove the avatar of the room
    fn remove_avatar() -> Future<Result<EventId>>;

    /// what is the description / topic
    fn topic() -> Option<string>;

    /// set description / topic of the room
    fn set_topic(topic: string) -> Future<Result<EventId>>;

    /// the members currently in the convo
    fn active_members_ids() -> Future<Result<Vec<string>>>;

    /// the members currently in the room
    fn active_members() -> Future<Result<Vec<Member>>>;

    /// the members invited to this room
    fn invited_members() -> Future<Result<Vec<Member>>>;

    /// get the room member by user id
    fn get_member(user_id: string) -> Future<Result<Member>>;

    /// Get the timeline for the room
    fn timeline_stream() -> TimelineStream;

    /// The last message sent to the room
    fn latest_message() -> Option<RoomMessage>;

    /// Latest message timestamp or 0
    fn latest_message_ts() -> u64;

    /// the Membership of myself
    fn get_my_membership() -> Future<Result<Member>>;

    /// the room id
    fn get_room_id() -> RoomId;

    /// the room id as str
    fn get_room_id_str() -> string;

    /// Activate typing notice for this room
    /// The typing notice remains active for 4s. It can be deactivate at any
    /// point by setting typing to false. If this method is called while the
    /// typing notice is active nothing will happen. This method can be called
    /// on every key stroke, since it will do nothing while typing is active.
    fn typing_notice(typing: bool) -> Future<Result<bool>>;

    /// decrypted media file data
    /// if thumb size is given, media thumbnail is returned
    /// if thumb size is not given, media file is returned
    /// The reason that this function belongs to room object is because ChatScreen keeps it as member variable
    /// If this function belongs to message object, we may have to load too many message objects in ChatScreen
    fn media_binary(event_id: string, thumb_size: Option<ThumbnailSize>) -> Future<Result<buffer<u8>>>;

    /// get the user status on this room
    fn room_type() -> string;

    /// is this a direct message
    fn is_dm() -> bool;

    /// is this a favorite chat
    fn is_favorite() -> bool;

    /// set this a favorite chat
    fn set_favorite(is_favorite: bool) -> Future<Result<bool>>;

    /// is this a low priority chat
    fn is_low_priority() -> bool;

    /// the list of users ids if this is a direct message
    fn dm_users() -> Vec<string>;

    /// invite the new user to this room
    fn invite_user(user_id: string) -> Future<Result<bool>>;

    /// generate the room permalink
    fn permalink() -> Future<Result<string>>;
    /// join this room
    fn join() -> Future<Result<bool>>;

    /// leave this room
    fn leave() -> Future<Result<bool>>;

    /// get the users that were invited to this room
    fn get_invitees() -> Future<Result<Vec<Member>>>;

    /// download media (image/audio/video/file/location) to specified path
    /// if thumb size is given, media thumbnail is returned
    /// if thumb size is not given, media file is returned
    fn download_media(event_id: string, thumb_size: Option<ThumbnailSize>, dir_path: string) -> Future<Result<OptionString>>;

    /// get the path that media (image/audio/video/file) was saved
    /// return None when never downloaded
    fn media_path(event_id: string, is_thumb: bool) -> Future<Result<OptionString>>;

    /// initially called to get receipt status of room members
    fn user_receipts() -> Future<Result<Vec<ReceiptRecord>>>;

    /// whether this room is encrypted one
    fn is_encrypted() -> Future<Result<bool>>;

    /// redact any message (including text/image/file and reaction)
    /// sender_id refers to the user that sent original msg
    fn redact_message(event_id: string, sender_id: string, reason: Option<string>, txn_id: Option<string>) -> Future<Result<EventId>>;

    /// update the power levels of specified member
    fn update_power_level(user_id: string, level: i32) -> Future<Result<EventId>>;

    /// report an event from this room
    /// score - The score to rate this content as where -100 is most offensive and 0 is inoffensive (optional).
    /// reason - The reason for the event being reported (optional).
    fn report_content(event_id: string, score: Option<i32>, reason: Option<string>) -> Future<Result<bool>>;

    /// redact an event from this room
    /// reason - The reason for the event being reported (optional).
    fn redact_content(event_id: string, reason: Option<string>) -> Future<Result<EventId>>;

    fn is_joined() -> bool;
}


//   ######   #######  ##     ## ##     ## ######## ##    ## ########  ######  
//  ##    ## ##     ## ###   ### ###   ### ##       ###   ##    ##    ##    ## 
//  ##       ##     ## #### #### #### #### ##       ####  ##    ##    ##       
//  ##       ##     ## ## ### ## ## ### ## ######   ## ## ##    ##     ######  
//  ##       ##     ## ##     ## ##     ## ##       ##  ####    ##          ## 
//  ##    ## ##     ## ##     ## ##     ## ##       ##   ###    ##    ##    ## 
//   ######   #######  ##     ## ##     ## ######## ##    ##    ##     ######  


object CommentDraft {
    /// set the content of the draft to body
    fn content_text(body: string);

    /// set the content to a formatted body of html_body, where body is the tag-stripped version
    fn content_formatted(body: string, html_body: string);

    /// fire this comment over - the event_id is the confirmation from the server.
    fn send() -> Future<Result<EventId>>;
}

object Comment {
    /// Who send this comment
    fn sender() -> UserId;
    /// When was this comment acknowledged by the server
    fn origin_server_ts() -> u64;
    /// what is the comment's content
    fn msg_content() -> MsgContent;
    /// create a draft builder to reply to this comment
    fn reply_builder() -> CommentDraft;
}

/// Reference to the comments section of a particular item
object CommentsManager {
    /// Get the list of comments (in arrival order)
    fn comments() -> Future<Result<Vec<Comment>>>;

    /// Does this item have any comments?
    fn has_comments() -> bool;

    /// How many comments does this item have
    fn comments_count() -> u32;

    /// draft a new comment for this item
    fn comment_draft() -> CommentDraft;

    /// subscribe to the changes this manager
    fn subscribe_stream() -> Stream<bool>;

    /// reload the data from the database
    fn reload() -> Future<Result<CommentsManager>>;
}


//     ###    ######## ########    ###     ######  ##     ## ##     ## ######## ##    ## ########  ######  
//    ## ##      ##       ##      ## ##   ##    ## ##     ## ###   ### ##       ###   ##    ##    ##    ## 
//   ##   ##     ##       ##     ##   ##  ##       ##     ## #### #### ##       ####  ##    ##    ##       
//  ##     ##    ##       ##    ##     ## ##       ######### ## ### ## ######   ## ## ##    ##     ######  
//  #########    ##       ##    ######### ##       ##     ## ##     ## ##       ##  ####    ##          ## 
//  ##     ##    ##       ##    ##     ## ##    ## ##     ## ##     ## ##       ##   ###    ##    ##    ## 
//  ##     ##    ##       ##    ##     ##  ######  ##     ## ##     ## ######## ##    ##    ##     ######  



object AttachmentDraft {
    /// fire this attachment over - the event_id is the confirmation from the server.
    fn send() -> Future<Result<EventId>>;
}

object Attachment {
    /// Who send this attachment
    fn sender() -> string;
    /// When was this attachment acknowledged by the server
    fn origin_server_ts() -> u64;
    /// unique event id associated with this attachment
    fn attachment_id_str() -> string;
    /// the room this attachment lives in
    fn room_id_str() -> string;
    /// the type of attachment
    fn type_str() -> string;
    /// if this is a media, hand over the description
    fn msg_content() -> MsgContent;
    /// if this is a media, hand over the data
    /// if thumb size is given, media thumbnail is returned
    /// if thumb size is not given, media file is returned
    fn source_binary(thumb_size: Option<ThumbnailSize>) -> Future<Result<buffer<u8>>>;
}

/// Reference to the attachments section of a particular item
object AttachmentsManager {
    /// Get the list of attachments (in arrival order)
    fn attachments() -> Future<Result<Vec<Attachment>>>;

    /// Does this item have any attachments?
    fn has_attachments() -> bool;

    /// How many attachments does this item have
    fn attachments_count() -> u32;

    /// create news slide for image msg
    fn content_draft(base_draft: MsgContentDraft) -> Future<Result<AttachmentDraft>>;

    // inform about the changes to this manager
    fn reload() -> Future<Result<AttachmentsManager>>;
    
    // redact attachment 
    fn redact(attachment_id: string, reason: Option<string>, txn_id: Option<string>) -> Future<Result<EventId>>;

    /// subscribe to the changes of this model key
    fn subscribe_stream() -> Stream<bool>;
}


//  ########    ###     ######  ##    ##  ######  
//     ##      ## ##   ##    ## ##   ##  ##    ## 
//     ##     ##   ##  ##       ##  ##   ##       
//     ##    ##     ##  ######  #####     ######  
//     ##    #########       ## ##  ##         ## 
//     ##    ##     ## ##    ## ##   ##  ##    ## 
//     ##    ##     ##  ######  ##    ##  ######  



object Task {
    /// the name of this task
    fn title() -> string;

    /// unique event id associated with this task
    fn event_id_str() -> string;
    /// the room this task lives in
    fn room_id_str() -> string;

    /// unique task list id associated with this task
    fn task_list_id_str() -> string;

    /// the description of this task
    fn description() -> Option<MsgContent>;

    /// initial author
    fn author_str() -> string;

    /// the users assigned
    fn assignees_str() -> Vec<string>;

    /// order in the list
    fn sort_order() -> u32;

    /// does this list have a special role?
    /// Highest = 1,
    /// SecondHighest = 2,
    /// Three = 3,
    /// Four = 4,
    /// Five = 5,
    /// Six = 6,
    /// Seven = 7,
    ///  --- No value
    /// SecondLowest = 8,
    /// Lowest = 9,
    fn priority() -> Option<u8>;

    /// Day When this is due
    fn due_date() -> Option<string>;

    /// Time of day when this is due compared to UTC00:00
    fn utc_due_time_of_day() -> Option<i32>;

    /// When this was started
    fn utc_start_rfc3339() -> Option<string>;

    /// Has this been colored in?
    fn color() -> Option<u32>;

    /// is this task already done?
    fn is_done() -> bool;

    /// if it has been started, haw far is it in percent 0->100
    /// None if not yet started
    fn progress_percent() -> Option<u8>;

    /// tags on this task
    fn keywords() -> Vec<string>;

    /// categories this task is in
    fn categories() -> Vec<string>;

    /// make a builder for updating the task
    fn update_builder() -> Result<TaskUpdateBuilder>;

    /// Is this assigned to the current user?
    fn is_assigned_to_me() -> bool;

    /// Assign this task to myself
    fn assign_self() -> Future<Result<EventId>>;

    /// UnAssign this task to myself
    fn unassign_self() -> Future<Result<EventId>>;

    /// get informed about changes to this task
    fn subscribe_stream() -> Stream<bool>;

    /// replace the current task with one with the latest state
    fn refresh() -> Future<Result<Task>>;

    /// get the comments manager for this task
    fn comments() -> Future<Result<CommentsManager>>;
}

object TaskUpdateBuilder {
    /// set the title for this task
    fn title(title: string);
    fn unset_title_update();

    /// set the description for this task list
    fn description_text(text: string);
    fn unset_description();
    fn unset_description_update();

    /// set the sort order for this task list
    fn sort_order(sort_order: u32);
    fn unset_sort_order_update();

    /// set the color for this task list
    fn color(color: u32);
    fn unset_color();
    fn unset_color_update();

    /// set the due day for this task
    fn due_date(year: i32, month: u32, day: u32);
    fn unset_due_date();
    fn unset_due_date_update();

    /// set the due time of day in seconds since midnight UTC
    fn utc_due_time_of_day(seconds: i32);
    fn unset_utc_due_time_of_day();
    fn unset_utc_due_time_of_day_update();

    /// set the utc_start for this task list in rfc3339 format
    fn utc_start_from_rfc3339(utc_start: string) -> Result<()>;
    /// set the utc_start for this task list in rfc2822 format
    fn utc_start_from_rfc2822(utc_start: string) -> Result<()>;
    /// set the utc_start for this task list in custom format
    fn utc_start_from_format(utc_start: string, format: string) -> Result<()>;
    fn unset_utc_start();
    fn unset_utc_start_update();

    /// set the sort order for this task list
    fn progress_percent(progress_percent: u8);
    fn unset_progress_percent();
    fn unset_progress_percent_update();

    /// set the keywords for this task list
    fn keywords(keywords: Vec<string>);
    fn unset_keywords();
    fn unset_keywords_update();

    /// set the categories for this task list
    fn categories(categories: Vec<string>);
    fn unset_categories();
    fn unset_categories_update();

    /// send this task list draft
    /// mark it done
    fn mark_done();

    /// mark as not done
    fn mark_undone();

    /// update this task
    fn send() -> Future<Result<EventId>>;
}

object TaskDraft {
    /// set the title for this task
    fn title(title: string);

    /// set the description for this task
    fn description_text(text: string);
    fn unset_description();

    /// set the sort order for this task
    fn sort_order(sort_order: u32);

    /// set the color for this task
    fn color(color: u32);
    fn unset_color();

    /// set the due day for this task
    fn due_date(year: i32, month: u32, day: u32);
    fn unset_due_date();
    /// set the due time of day in seconds since midnight UTC
    fn utc_due_time_of_day(seconds: i32);
    fn unset_utc_due_time_of_day();

    /// set the utc_start for this task in rfc3339 format
    fn utc_start_from_rfc3339(utc_start: string) -> Result<()>;
    /// set the utc_start for this task in rfc2822 format
    fn utc_start_from_rfc2822(utc_start: string) -> Result<()>;
    /// set the utc_start for this task in custom format
    fn utc_start_from_format(utc_start: string, format: string) -> Result<()>;
    fn unset_utc_start();

    /// set the sort order for this task
    fn progress_percent(progress_percent: u8);
    fn unset_progress_percent();

    /// set the keywords for this task
    fn keywords(keywords: Vec<string>);
    fn unset_keywords();

    /// set the categories for this task
    fn categories(categories: Vec<string>);
    fn unset_categories();

    /// create this task
    fn send() -> Future<Result<EventId>>;
}

object TaskList {
    /// the name of this task list
    fn name() -> string;

    /// the event_id of this task list
    fn event_id_str() -> string;

    /// the description of this task list
    fn description() -> Option<MsgContent>;

    /// does this list have a special role?
    fn role() -> Option<string>;

    /// order in the list
    fn sort_order() -> u32;

    /// Has this been colored in?
    fn color() -> Option<u32>;

    /// Does this have any special time zone
    fn time_zone() -> Option<string>;

    /// tags on this task
    fn keywords() -> Vec<string>;

    /// categories this task is in
    fn categories() -> Vec<string>;

    /// The tasks belonging to this tasklist
    fn tasks() -> Future<Result<Vec<Task>>>;

    /// The specific task belonging to this task list
    fn task(task_id: string) -> Future<Result<Task>>;

    /// make a builder for creating the task draft
    fn task_builder() -> Result<TaskDraft>;

    /// make a builder for updating the task list
    fn update_builder() -> Result<TaskListUpdateBuilder>;

    /// get informed about changes to this task
    fn subscribe_stream() -> Stream<bool>;

    /// replace the current task with one with the latest state
    fn refresh() -> Future<Result<TaskList>>;

    /// the space this TaskList belongs to
    fn space() -> Space;

    /// the id of the space this TaskList belongs to
    fn space_id_str() -> string;
}

object TaskListDraft {
    /// set the name for this task list
    fn name(name: string);

    /// set the description for this task list
    fn description_text(text: string);
    fn description_markdown(text: string);
    fn unset_description();

    /// set the sort order for this task list
    fn sort_order(sort_order: u32);

    /// set the color for this task list
    fn color(color: u32);
    fn unset_color();

    /// set the keywords for this task list
    fn keywords(keywords: Vec<string>);
    fn unset_keywords();

    /// set the categories for this task list
    fn categories(categories: Vec<string>);
    fn unset_categories();

    /// create this task list
    fn send() -> Future<Result<EventId>>;
}

object TaskListUpdateBuilder {
    /// set the name for this task list
    fn name(name: string);

    /// set the description for this task list
    fn description_text(text: string);
    fn unset_description();
    fn unset_description_update();

    /// set the sort order for this task list
    fn sort_order(sort_order: u32);

    /// set the color for this task list
    fn color(color: u32);
    fn unset_color();
    fn unset_color_update();

    /// set the keywords for this task list
    fn keywords(keywords: Vec<string>);
    fn unset_keywords();
    fn unset_keywords_update();

    /// set the categories for this task list
    fn categories(categories: Vec<string>);
    fn unset_categories();
    fn unset_categories_update();

    /// update this task
    fn send() -> Future<Result<EventId>>;
}


//   ######  ########     ###     ######  ########    ########  ######## ##       
//  ##    ## ##     ##   ## ##   ##    ## ##          ##     ## ##       ##       
//  ##       ##     ##  ##   ##  ##       ##          ##     ## ##       ##       
//   ######  ########  ##     ## ##       ######      ########  ######   ##       
//        ## ##        ######### ##       ##          ##   ##   ##       ##       
//  ##    ## ##        ##     ## ##    ## ##          ##    ##  ##       ##       
//   ######  ##        ##     ##  ######  ########    ##     ## ######## ######## 




enum RelationTargetType {
    Unknown,
    ChatRoom,
    Space,
    ActerSpace
}

/// remote info
object SpaceHierarchyRoomInfo {
    fn name() -> Option<string>;
    //fn room_id() -> OwnedRoomId;
    fn room_id_str() -> string;
    fn topic() -> Option<string>;
    fn num_joined_members() -> u64;
    fn world_readable() -> bool;
    fn guest_can_join() -> bool;
    fn is_space() -> bool;
    fn avatar_url_str() -> Option<string>;
    fn join_rule_str() -> string;
    /// whether to have avatar
    fn has_avatar() -> bool;

    /// get the binary data of avatar
    /// if thumb size is given, avatar thumbnail is returned
    /// if thumb size is not given, avatar file is returned
    fn get_avatar(thumb_size: Option<ThumbnailSize>) -> Future<Result<OptionBuffer>>;
    // recommended server to try to join via
    fn via_server_name() -> Option<string>;
}

object SpaceHierarchyListResult {
    /// to be used for the next `since`
    fn next_batch() -> Option<string>;
    /// get the chunk of items in this response
    fn rooms() -> Future<Result<Vec<SpaceHierarchyRoomInfo>>>;
}

object SpaceRelation {
    /// the room ID this Relation links to
    fn room_id() -> RoomId;
    /// is this a suggested room?
    fn suggested() -> bool;
    /// how to find this room
    fn via() -> Vec<string>;
    /// of what type is the targeted room?
    fn target_type() -> string;
}

object SpaceRelations {
    //fn room_id() -> OwnedRoomId;
    fn room_id_str() -> string;
    /// do we have a canonical parent?!?
    fn main_parent() -> Option<SpaceRelation>;
    /// other parents we belong to
    fn other_parents() -> Vec<SpaceRelation>;
    /// children
    fn children() -> Vec<SpaceRelation>;
    /// query for children from the server
    fn query_hierarchy(from: Option<string>) -> Future<Result<SpaceHierarchyListResult>>;
}

object RoomPowerLevels {
    fn news() -> Option<i64>;
    fn news_key() -> string;
    fn events() -> Option<i64>;
    fn events_key() -> string;
    fn pins() -> Option<i64>;
    fn pins_key() -> string;
    fn events_default() -> i64;
    fn users_default() -> i64;
    fn max_power_level() -> i64;

    fn tasks() -> Option<i64>;
    fn tasks_key() -> string;

    fn task_lists() -> Option<i64>;
    fn task_lists_key() -> string;
}

object SimpleSettingWithTurnOff {

}

object SimpleSettingWithTurnOffBuilder {
    fn active(active: bool);
    fn build() -> Result<SimpleSettingWithTurnOff>;
}


object TasksSettingsBuilder {
    fn active(active: bool);
    fn build() -> Result<TasksSettings>;
}
object NewsSettings {
    fn active() -> bool;
    fn updater() -> SimpleSettingWithTurnOffBuilder;
}

object TasksSettings {
    fn active() -> bool;
    fn updater() -> TasksSettingsBuilder;
}

object EventsSettings {
    fn active() -> bool;
    fn updater() -> SimpleSettingWithTurnOffBuilder;
}

object PinsSettings {
    fn active() -> bool;
    fn updater() -> SimpleSettingWithTurnOffBuilder;
}

object ActerAppSettings {
    fn news() -> NewsSettings;
    fn pins() -> PinsSettings;
    fn events() -> EventsSettings;
    fn tasks() -> TasksSettings;
    fn update_builder() -> ActerAppSettingsBuilder;
}

object ActerAppSettingsBuilder {
    fn news(news: Option<SimpleSettingWithTurnOff>);
    fn pins(pins: Option<SimpleSettingWithTurnOff>);
    fn events(events: Option<SimpleSettingWithTurnOff>);
    fn tasks(tasks: Option<TasksSettings>);
}


//   ######  ########     ###     ######  ######## 
//  ##    ## ##     ##   ## ##   ##    ## ##       
//  ##       ##     ##  ##   ##  ##       ##       
//   ######  ########  ##     ## ##       ######   
//        ## ##        ######### ##       ##       
//  ##    ## ##        ##     ## ##    ## ##       
//   ######  ##        ##     ##  ######  ######## 


object Space {
    /// get the room profile that contains avatar and display name
    fn get_profile() -> RoomProfile;

    /// get the room profile that contains avatar and display name
    fn space_relations() -> Future<Result<SpaceRelations>>;

    /// Whether this space is a child of the given space
    fn is_child_space_of(room_id: string) -> Future<bool>;

    /// add the following as a child space and return event id of that event
    fn add_child_room(room_id: string) -> Future<Result<string>>;

    /// remove a child space
    fn remove_child_room(room_id: string, reason: Option<string>) -> Future<Result<bool>>;

    /// Change the avatar of the room
    fn upload_avatar(uri: string) -> Future<Result<MxcUri>>;

    fn set_acter_space_states() -> Future<Result<bool>>;

    /// Remove the avatar of the room
    fn remove_avatar() -> Future<Result<EventId>>;

    /// what is the description / topic
    fn topic() -> Option<string>;

    fn is_joined() -> bool;

    /// set description / topic of the room
    fn set_topic(topic: string) -> Future<Result<EventId>>;

    /// set name of the room
    fn set_name(name: string) -> Future<Result<EventId>>;

    /// the members currently in the space
    fn active_members_ids() -> Future<Result<Vec<string>>>;

    /// the members currently in the space
    fn active_members() -> Future<Result<Vec<Member>>>;

    /// the members invited to this room
    fn invited_members() -> Future<Result<Vec<Member>>>;

    /// the room id
    fn get_room_id() -> RoomId;

    /// invite the new user to this space
    fn invite_user(user_id: string) -> Future<Result<bool>>;

    /// the room id as str
    fn get_room_id_str() -> string;

    /// the members currently in the room
    fn get_member(user_id: string) -> Future<Result<Member>>;

    /// the Membership of myself
    fn get_my_membership() -> Future<Result<Member>>;

    /// whether this room is encrypted one
    fn is_encrypted() -> Future<Result<bool>>;

    /// whether or not this space is public
    fn is_public() -> bool;

    /// join rules for this space.
    fn join_rule_str() -> string;

    /// the ids of the rooms the restriction applies to
    fn restricted_room_ids_str() -> Vec<string>;

    /// whether or not this space has been marked as an 'acter' one
    fn is_acter_space() -> Future<Result<bool>>;

    /// the Tasks lists of this Space
    fn task_lists() -> Future<Result<Vec<TaskList>>>;

    /// the Tasks list of this Space
    fn task_list(key: string) -> Future<Result<TaskList>>;

    /// task list draft builder
    fn task_list_draft() -> Result<TaskListDraft>;

    /// get latest news
    fn latest_news_entries(count: u32) -> Future<Result<Vec<NewsEntry>>>;

    /// get all calendar events
    fn calendar_events() -> Future<Result<Vec<CalendarEvent>>>;

    /// create calendart event draft
    fn calendar_event_draft() -> Result<CalendarEventDraft>;

    /// create news draft
    fn news_draft() -> Result<NewsEntryDraft>;

    /// the pins of this Space
    fn pins() -> Future<Result<Vec<ActerPin>>>;

    /// the links pinned to this Space
    fn pinned_links() -> Future<Result<Vec<ActerPin>>>;

    /// pin draft builder
    fn pin_draft() -> Result<PinDraft>;

    /// join this room
    fn join() -> Future<Result<bool>>;

    /// leave this room
    fn leave() -> Future<Result<bool>>;

    /// the power levels currently set up
    fn power_levels() -> Future<Result<RoomPowerLevels>>;

    /// current App Settings
    fn app_settings() -> Future<Result<ActerAppSettings>>;

    /// Whenever this is submitted;
    fn update_app_settings(new_settings: ActerAppSettingsBuilder) -> Future<Result<string>>;

    /// update the power level for a feature
    fn update_feature_power_levels(feature: string, level: Option<i32>) -> Future<Result<bool>>;

    /// report an event from this room
    /// score - The score to rate this content as where -100 is most offensive and 0 is inoffensive (optional).
    /// reason - The reason for the event being reported (optional).
    fn report_content(event_id: string, score: Option<i32>, reason: Option<string>) -> Future<Result<bool>>;

    /// redact an event from this room
    /// reason - The reason for the event being reported (optional).
    fn redact_content(event_id: string, reason: Option<string>) -> Future<Result<EventId>>;
}

enum MembershipStatus {
    Admin,
    Mod,
    Custom,
    Regular
}

enum MemberPermission {
    CanSendChatMessages,
    CanToggleReaction,
    CanSendSticker,
    CanPostNews,
    CanPostPin,
    CanPostEvent,
    CanPostTaskList,
    CanPostTask,
    CanBan,
    CanKick,
    CanInvite,
    CanRedactOwn,
    CanRedactOther,
    CanTriggerRoomNotification,
    CanUpgradeToActerSpace,
    CanSetName,
    CanUpdateAvatar,
    CanSetTopic,
    CanLinkSpaces,
    CanUpdatePowerLevels,
    CanSetParentSpace,
    CanChangeAppSettings
}

object Member {
    /// get the user profile that contains avatar and display name
    fn get_profile() -> UserProfile;

    /// Full user_id
    fn user_id() -> UserId;

    /// The status of this member.
    fn membership_status_str() -> string;

    /// the power level this user has
    fn power_level() -> i64;

    /// Whether this user is allowed to perform the given action
    //fn can(permission: MemberPermission) -> bool;
    fn can_string(permission: string) -> bool;

    /// whether the user is being ignored
    fn is_ignored() -> bool;

    /// add this member to ignore list
    fn ignore() -> Future<Result<bool>>;

    /// remove this member from ignore list
    fn unignore() -> Future<Result<bool>>;
}

object Account {
    /// get user id of this account
    fn user_id() -> UserId;

    /// The display_name of the account
    fn display_name() -> Future<Result<OptionString>>;

    /// Change the display name of the account
    fn set_display_name(name: string) -> Future<Result<bool>>;

    /// The avatar of the client
    /// if thumb size is given, avatar thumbnail is returned
    /// if thumb size is not given, avatar file is returned
    fn avatar(thumb_size: Option<ThumbnailSize>) -> Future<Result<OptionBuffer>>;

    /// Change the avatar of the account with the provided
    /// local file path
    fn upload_avatar(uri: string) -> Future<Result<MxcUri>>;

    /// list of users by blocked by this user
    fn ignored_users() -> Future<Result<Vec<UserId>>>;

    /// add user_id to ignore list
    fn ignore_user(user_id: string) -> Future<Result<bool>>;

    /// remove user_id from ignore list
    fn unignore_user(user_id: string) -> Future<Result<bool>>;
}

object ThreePidManager {
    /// get email addresses from third party identifier
    fn confirmed_email_addresses() -> Future<Result<Vec<string>>>;

    /// get email addresses that were registered
    fn requested_email_addresses() -> Future<Result<Vec<string>>>;

    /// Requests token via email and add email address to third party identifier.
    /// If password is not enough complex, homeserver may reject this request.
    fn request_token_via_email(email_address: string) -> Future<Result<bool>>;

    /// Submit token to finish email register
    fn submit_token_from_email(email_address: string, token: string, password: string) -> Future<Result<bool>>;

    /// Submit token to finish email register
    fn try_confirm_email_status(email_address: string, password: string) -> Future<Result<bool>>;

    /// Remove email address from confirmed list or unconfirmed list
    fn remove_email_address(email_address: string) -> Future<Result<bool>>;
}

object SyncState {
    /// Get event handler of first synchronization on every launch
    fn first_synced_rx() -> Stream<bool>;

    /// When the sync stopped with an error, this will trigger
    fn sync_error_rx() -> Stream<string>;

    /// stop the sync loop
    fn cancel();
}


//   ######  ########    ###    ########   ######  ##     ## 
//  ##    ## ##         ## ##   ##     ## ##    ## ##     ## 
//  ##       ##        ##   ##  ##     ## ##       ##     ## 
//   ######  ######   ##     ## ########  ##       ######### 
//        ## ##       ######### ##   ##   ##       ##     ## 
//  ##    ## ##       ##     ## ##    ##  ##    ## ##     ## 
//   ######  ######## ##     ## ##     ##  ######  ##     ## 



object PublicSearchResultItem {
    fn name() -> Option<string>;
    fn topic() -> Option<string>;
    fn world_readable() -> bool;
    fn guest_can_join() -> bool;
    // fn canonical_alias() -> Option<OwnedRoomAliasId>;
    fn canonical_alias_str() -> Option<string>;
    fn num_joined_members() -> u64;
    // fn room_id() -> OwnedRoomId;
    fn room_id_str() -> string;
    // fn avatar_url() -> Option<OwnedMxcUri>;
    fn avatar_url_str() -> Option<string>;
    // fn join_rule() -> PublicRoomJoinRule;
    fn join_rule_str() -> string;
    // fn room_type() -> Option<RoomType>;
    fn room_type_str() -> string;
}

object PublicSearchResult {
    /// to be used for the next `since`
    fn next_batch() -> Option<string>;
    /// to get the previous page
    fn prev_batch() -> Option<string>;
    /// an estimated total of matches
    fn total_room_count_estimate() -> Option<u64>;
    /// get the chunk of items in this response
    fn chunks() -> Vec<PublicSearchResultItem>;
}



//  ##    ##  #######  ######## #### ######## ####  ######     ###    ######## ####  #######  ##    ##  ######  
//  ###   ## ##     ##    ##     ##  ##        ##  ##    ##   ## ##      ##     ##  ##     ## ###   ## ##    ## 
//  ####  ## ##     ##    ##     ##  ##        ##  ##        ##   ##     ##     ##  ##     ## ####  ## ##       
//  ## ## ## ##     ##    ##     ##  ######    ##  ##       ##     ##    ##     ##  ##     ## ## ## ##  ######  
//  ##  #### ##     ##    ##     ##  ##        ##  ##       #########    ##     ##  ##     ## ##  ####       ## 
//  ##   ### ##     ##    ##     ##  ##        ##  ##    ## ##     ##    ##     ##  ##     ## ##   ### ##    ## 
//  ##    ##  #######     ##    #### ##       ####  ######  ##     ##    ##    ####  #######  ##    ##  ######  


object NotificationSender {
    fn user_id() -> string;
    fn display_name() -> Option<string>;
    fn has_image() -> bool;
    fn image() -> Future<Result<buffer<u8>>>;
}

object NotificationRoom {
    fn room_id() -> string;
    fn display_name() -> string;
    fn has_image() -> bool;
    fn image() -> Future<Result<buffer<u8>>>;
}


// converting a room_id+event_id into the notification item to show
// from push context.
object NotificationItem {
    fn push_style() -> string;
    fn title() -> string;
    fn sender() -> NotificationSender;
    fn room() -> NotificationRoom;
    fn target_url() -> string;
    fn body() -> Option<MsgContent>;
    fn icon_url() -> Option<string>;
    fn thread_id() -> Option<string>;
    fn noisy() -> bool;
    fn has_image() -> bool;
    fn image() -> Future<Result<buffer<u8>>>;
    fn image_path(tmp_dir: string) -> Future<Result<string>>;

    // if this is an invite, this the room it invites to
    fn room_invite() -> Option<string>;
}

/// The pusher we sent notifications via to the user
object Pusher {
    fn is_email_pusher() -> bool;
    fn pushkey() -> string;
    fn app_id() -> string;
    fn app_display_name() -> string;
    fn device_display_name() -> string;
    fn lang() -> string;
    fn profile_tag() -> Option<string>;

    fn delete() -> Future<Result<bool>>;
}


//   ######  ########  ########    ###    ######## ######## 
//  ##    ## ##     ## ##         ## ##      ##    ##       
//  ##       ##     ## ##        ##   ##     ##    ##       
//  ##       ########  ######   ##     ##    ##    ######   
//  ##       ##   ##   ##       #########    ##    ##       
//  ##    ## ##    ##  ##       ##     ##    ##    ##       
//   ######  ##     ## ######## ##     ##    ##    ######## 



/// make convo settings builder
fn new_convo_settings_builder() -> CreateConvoSettingsBuilder;

object CreateConvoSettingsBuilder {
    /// set the name of convo
    fn set_name(value: string);

    /// set the alias of convo
    fn set_alias(value: string);

    /// append user id that will be invited to this space
    fn add_invitee(value: string) -> Result<()>;

    /// set the topic of convo
    fn set_topic(value: string);

    /// set the avatar uri of convo
    /// both remote and local are allowed
    fn set_avatar_uri(value: string);

    /// set the parent of convo
    fn set_parent(value: string);

    fn build() -> CreateConvoSettings;
}

object CreateConvoSettings {}

/// make space settings builder
fn new_space_settings_builder() -> CreateSpaceSettingsBuilder;

object CreateSpaceSettingsBuilder {
    /// set the name of convo
    fn set_name(value: string);

    /// set the space's visibility to either Public or Private
    fn set_visibility(value: string);

    /// append user id that will be invited to this space
    fn add_invitee(value: string) -> Result<()>;

    /// set the alias of space
    fn set_alias(value: string);

    /// set the topic of space
    fn set_topic(value: string);

    /// set the avatar uri of space
    /// both remote and local are allowed
    fn set_avatar_uri(value: string);

    /// set the parent of space
    fn set_parent(value: string);

    fn build() -> CreateSpaceSettings;
}

object CreateSpaceSettings {}


//   ######  ##       #### ######## ##    ## ######## 
//  ##    ## ##        ##  ##       ###   ##    ##    
//  ##       ##        ##  ##       ####  ##    ##    
//  ##       ##        ##  ######   ## ## ##    ##    
//  ##       ##        ##  ##       ##  ####    ##    
//  ##    ## ##        ##  ##       ##   ###    ##    
//   ######  ######## #### ######## ##    ##    ##    



/// Main entry point for `acter`.
object Client {

    // deactivate the account. This can not be reversed. The username will
    // be blocked from any future usage, all personal data will be removed.
    fn deactivate(password: string) -> Future<Result<bool>>;

    // Special

    /// start the sync
    fn start_sync() -> SyncState;

    /// Get the restore token for this session
    fn restore_token() -> Future<Result<string>>;

    /// Whether the client is registered as a guest account
    fn is_guest() -> bool;

    /// Whether the client has finished a first sync run
    fn has_first_synced() -> bool;

    /// Whether the client is syncing
    fn is_syncing() -> bool;

    /// Whether the client is logged in
    fn logged_in() -> bool;

    /// return the account of the logged in user, if given
    fn account() -> Result<Account>;

    /// The device_id of the client
    fn device_id() -> Result<DeviceId>;

    /// The user_id of the client
    /// deprecated, please use account() instead.
    fn user_id() -> Result<UserId>;

    /// Get the generic room that user belongs to
    fn room(room_id_or_alias: string) -> Future<Result<Room>>;

    /// get convo room
    fn convo(room_id_or_alias: string) -> Future<Result<Convo>>;

    /// has convo room
    fn has_convo(room_id: string) -> Future<bool>;

    /// get convo room of retry 250ms for retry times
    fn convo_with_retry(room_id_or_alias: string, retry: u8) -> Future<Result<Convo>>;

    /// get the room id of dm from user id
    fn dm_with_user(user_id: string) -> Result<OptionString>;

    /// upload file and return remote url
    fn upload_media(uri: string) -> Future<Result<MxcUri>>;

    /// Fires whenever the convo list changes (in order or number)
    /// fires immediately with the current state of convos
    fn convos_stream() -> Stream<ConvoDiff>;

    /// The spaces the user is part of
    fn spaces() -> Future<Result<Vec<Space>>>;

    /// Fires whenever the space list changes (in order or number)
    /// fires immediately with the current state of spaces
    fn spaces_stream() -> Stream<SpaceDiff>;

    /// attempt to join a space
    fn join_space(room_id_or_alias: string, server_name: Option<string>) -> Future<Result<Space>>;

    /// attempt to join a room
    fn join_convo(room_id_or_alias: string, server_name: Option<string>) -> Future<Result<Convo>>;

    /// search the public directory for spaces
    fn public_spaces(search_term: Option<string>, server: Option<string>, since: Option<string>) -> Future<Result<PublicSearchResult>>;

    /// Get the space that user belongs to
    fn space(room_id_or_alias: string) -> Future<Result<Space>>;

    /// Get the Pinned Links for the client
    fn pinned_links() -> Future<Result<Vec<ActerPin>>>;

    /// Get the invitation event stream
    fn invitations_rx() -> Stream<Vec<Invitation>>;

    /// the users out of room
    fn suggested_users_to_invite(room_name: string) -> Future<Result<Vec<UserProfile>>>;

    /// search the user directory
    fn search_users(search_term: string) -> Future<Result<Vec<UserProfile>>>;

    /// Whether the user already verified the device
    fn verified_device(dev_id: string) -> Future<Result<bool>>;

    /// log out this client
    fn logout() -> Future<Result<bool>>;

    /// Get the verification event receiver
    fn verification_event_rx() -> Option<Stream<VerificationEvent>>;

    /// Get session manager that returns all/verified/unverified/inactive session list
    fn session_manager() -> SessionManager;

    /// Return the event handler of device new
    fn device_new_event_rx() -> Option<Stream<DeviceNewEvent>>;

    /// Return the event handler of device changed
    fn device_changed_event_rx() -> Option<Stream<DeviceChangedEvent>>;

    /// Return the typing event receiver
    fn typing_event_rx() -> Option<Stream<TypingEvent>>;

    /// Return the receipt event receiver
    fn receipt_event_rx() -> Option<Stream<ReceiptEvent>>;

    /// create convo
    fn create_convo(settings: CreateConvoSettings) -> Future<Result<RoomId>>;

    /// create default space
    fn create_acter_space(settings: CreateSpaceSettings) -> Future<Result<RoomId>>;

    /// listen to updates to any model key
    fn subscribe_stream(key: string) -> Stream<bool>;

    /// Fetch the Comment or use its event_id to wait for it to come down the wire
    fn wait_for_comment(key: string, timeout: Option<u8>) -> Future<Result<Comment>>;

    /// Fetch the NewsEntry or use its event_id to wait for it to come down the wire
    fn wait_for_news(key: string, timeout: Option<u8>) -> Future<Result<NewsEntry>>;

    /// Get the latest News for the client
    fn latest_news_entries(count: u32) -> Future<Result<Vec<NewsEntry>>>;

    /// Fetch the ActerPin or use its event_id to wait for it to come down the wire
    fn wait_for_pin(key: string, timeout: Option<u8>) -> Future<Result<ActerPin>>;

    /// Get the Pins for the client
    fn pins() -> Future<Result<Vec<ActerPin>>>;

    /// Get a specific Pin for the client
    fn pin(pin_id: string) -> Future<Result<ActerPin>>;

    /// Fetch the Tasklist or use its event_id to wait for it to come down the wire
    fn task_list(key: string, timeout: Option<u8>) -> Future<Result<TaskList>>;

    /// the Tasks lists for the client
    fn task_lists() -> Future<Result<Vec<TaskList>>>;

    /// Fetch the Task or use its event_id to wait for it to come down the wire
    fn wait_for_task(key: string, timeout: Option<u8>) -> Future<Result<Task>>;

    /// the Tasks lists of this Space
    fn my_open_tasks() -> Future<Result<Vec<Task>>>;

    /// listen to updates of the my_open_tasks list
    fn subscribe_my_open_tasks_stream() -> Stream<bool>;

    /// get all calendar events
    fn calendar_events() -> Future<Result<Vec<CalendarEvent>>>;

    /// Get a specific Calendar Event for the client
    fn calendar_event(calendar_id: string) -> Future<Result<CalendarEvent>>;

    /// Fetch the calendar event or use its event_id to wait for it to come down the wire
    fn wait_for_calendar_event(key: string, timeout: Option<u8>) -> Future<Result<CalendarEvent>>;

    /// Fetch the reaction event or use its event_id to wait for it to come down the wire
    fn wait_for_reaction(key: string, timeout: Option<u8>) -> Future<Result<Reaction>>;

    /// Fetch the RSVP or use its event_id to wait for it to come down the wire
    fn wait_for_rsvp(key: string, timeout: Option<u8>) -> Future<Result<Rsvp>>;

    /// install the default acter push rules for fallback
    fn install_default_acter_push_rules() -> Future<Result<bool>>;

    /// list of pushers
    fn pushers() -> Future<Result<Vec<Pusher>>>;

    /// add another http pusher to the notification system
    fn add_pusher(app_id: string, token: string, device_name: string, app_name: string, server_url: string, with_ios_default: bool, lang: Option<string>) -> Future<Result<bool>>;

    /// add another http pusher to the notification system
    fn add_email_pusher(device_name: string, app_name: string, email: string, lang: Option<string>) -> Future<Result<bool>>;

    /// getting a notification item from the notification data;
    fn get_notification_item(room_id: string, event_id: string) -> Future<Result<NotificationItem>>;
    
    /// get all upcoming events, whether I responded or not
    fn all_upcoming_events(secs_from_now: Option<u32>) -> Future<Result<Vec<CalendarEvent>>>;

    /// get only upcoming events that I responded as rsvp
    fn my_upcoming_events(secs_from_now: Option<u32>) -> Future<Result<Vec<CalendarEvent>>>;

    /// get only past events that I responded as rsvp
    fn my_past_events(secs_from_now: Option<u32>) -> Future<Result<Vec<CalendarEvent>>>;

    /// get intermediate info of login (via email and phone) from account data
    fn three_pid_manager() -> Result<ThreePidManager>;

    /// super invites interface
    fn super_invites() -> SuperInvites;

    /// allow to configure notification settings
    fn notification_settings() -> Future<Result<NotificationSettings>>;

    /// the list of devices
    fn device_records(verified: bool) -> Future<Result<Vec<DeviceRecord>>>;

    /// make draft to send text plain msg
    fn text_plain_draft(body: string) -> MsgContentDraft;

    /// make draft to send text markdown msg
    fn text_markdown_draft(body: string) -> MsgContentDraft;

    /// make draft to send html marked up msg
    fn text_html_draft(html: string, plain: string) -> MsgContentDraft;

    /// make draft to send image msg
    fn image_draft(source: string, mimetype: string) -> MsgContentDraft;

    /// make draft to send audio msg
    fn audio_draft(source: string, mimetype: string) -> MsgContentDraft;

    /// make draft to send video msg
    fn video_draft(source: string, mimetype: string) -> MsgContentDraft;

    /// make draft to send file msg
    fn file_draft(source: string, mimetype: string) -> MsgContentDraft;

    /// make draft to send location msg
    fn location_draft(body: string, source: string) -> MsgContentDraft;
}

object NotificationSettings {

    /// get informed about changes to the notification settings
    fn changes_stream() -> Stream<bool>;

    /// default RoomNotificationMode for the selected features
    fn default_notification_mode(is_encrypted: bool, is_one_on_one: bool) -> Future<Result<string>>;

    /// set default RoomNotificationMode for this combination
    fn set_default_notification_mode(is_encrypted: bool, is_one_on_one: bool, mode: string) -> Future<Result<bool>>;
    

    /// app settings
    fn global_content_setting(app_key: string) -> Future<Result<bool>>;
    fn set_global_content_setting(app_key: string, enabled: bool) -> Future<Result<bool>>;
}


//  #### ##    ## ##     ## #### ########    ###    ######## ####  #######  ##    ##  ######  
//   ##  ###   ## ##     ##  ##     ##      ## ##      ##     ##  ##     ## ###   ## ##    ## 
//   ##  ####  ## ##     ##  ##     ##     ##   ##     ##     ##  ##     ## ####  ## ##       
//   ##  ## ## ## ##     ##  ##     ##    ##     ##    ##     ##  ##     ## ## ## ##  ######  
//   ##  ##  ####  ##   ##   ##     ##    #########    ##     ##  ##     ## ##  ####       ## 
//   ##  ##   ###   ## ##    ##     ##    ##     ##    ##     ##  ##     ## ##   ### ##    ## 
//  #### ##    ##    ###    ####    ##    ##     ##    ##    ####  #######  ##    ##  ######  



object Invitation {
    /// get the timestamp of this invitation in milliseconds
    fn origin_server_ts() -> Option<u64>;

    /// get the room id of this invitation
    fn room_id() -> RoomId;

    /// get the room name of this invitation
    fn room_name() -> Future<Result<string>>;

    /// get the user id of this invitation sender
    fn sender() -> UserId;

    /// get the user profile that contains avatar and display name
    fn get_sender_profile() -> Future<Result<UserProfile>>;

    /// accept invitation about me to this room
    fn accept() -> Future<Result<bool>>;

    /// reject invitation about me to this room
    fn reject() -> Future<Result<bool>>;
}


//   ######  ##     ## ########  ######## ########     #### ##    ## ##     ## #### ########    ###    ######## ####  #######  ##    ##  ######  
//  ##    ## ##     ## ##     ## ##       ##     ##     ##  ###   ## ##     ##  ##     ##      ## ##      ##     ##  ##     ## ###   ## ##    ## 
//  ##       ##     ## ##     ## ##       ##     ##     ##  ####  ## ##     ##  ##     ##     ##   ##     ##     ##  ##     ## ####  ## ##       
//   ######  ##     ## ########  ######   ########      ##  ## ## ## ##     ##  ##     ##    ##     ##    ##     ##  ##     ## ## ## ##  ######  
//        ## ##     ## ##        ##       ##   ##       ##  ##  ####  ##   ##   ##     ##    #########    ##     ##  ##     ## ##  ####       ## 
//  ##    ## ##     ## ##        ##       ##    ##      ##  ##   ###   ## ##    ##     ##    ##     ##    ##     ##  ##     ## ##   ### ##    ## 
//   ######   #######  ##        ######## ##     ##    #### ##    ##    ###    ####    ##    ##     ##    ##    ####  #######  ##    ##  ######  


object SuperInvites {
    /// the current tokens
    fn tokens() -> Future<Result<Vec<SuperInviteToken>>>;

    /// create a token updater to create a fresh token
    fn new_token_updater() -> SuperInvitesTokenUpdateBuilder;

    /// Send or update
    fn create_or_update_token(builder: SuperInvitesTokenUpdateBuilder) -> Future<Result<SuperInviteToken>>;

    /// delete the given token
    fn delete(token: string) -> Future<Result<bool>>;

    /// try to redeem a token
    fn redeem(token: string) -> Future<Result<Vec<string>>>;
}

object SuperInviteToken {
    /// the textual ID of the token
    fn token() -> string;

    /// whether or not this token will create a DM with the new user
    fn create_dm() -> bool;

    /// Which rooms the redeemer will be invited to
    fn rooms() -> Vec<string>;

    /// How often this token has been redeemed
    fn accepted_count() -> u32;

    /// Updater for this SuperInviteToken
    fn update_builder() -> SuperInvitesTokenUpdateBuilder;
}

/// Updater/Creator for an invite token
object SuperInvitesTokenUpdateBuilder {
    /// set the token name
    fn token(token: string);

    /// add a room to the updater
    fn add_room(room: string);

    /// remove a room from the updater
    fn remove_room(room: string);

    /// set the create_dm field
    fn create_dm(value: bool);
}


//  ##     ## ######## ########  #### ######## ####  ######     ###    ######## ####  #######  ##    ## 
//  ##     ## ##       ##     ##  ##  ##        ##  ##    ##   ## ##      ##     ##  ##     ## ###   ## 
//  ##     ## ##       ##     ##  ##  ##        ##  ##        ##   ##     ##     ##  ##     ## ####  ## 
//  ##     ## ######   ########   ##  ######    ##  ##       ##     ##    ##     ##  ##     ## ## ## ## 
//   ##   ##  ##       ##   ##    ##  ##        ##  ##       #########    ##     ##  ##     ## ##  #### 
//    ## ##   ##       ##    ##   ##  ##        ##  ##    ## ##     ##    ##     ##  ##     ## ##   ### 
//     ###    ######## ##     ## #### ##       ####  ######  ##     ##    ##    ####  #######  ##    ## 



object VerificationEvent {
    /// Get event type
    fn event_type() -> string;

    /// Get flow id (EventId or TransactionId)
    fn flow_id() -> Option<string>;

    /// Get user id of event sender
    fn sender() -> string;

    /// Get content by field
    fn get_content(key: string) -> Option<string>;

    /// Get emoji array
    fn emojis() -> Vec<VerificationEmoji>;

    /// Get emoji array
    fn get_emojis() -> Future<Result<Vec<VerificationEmoji>>>;

    /// Bob accepts the verification request from Alice
    fn accept_verification_request() -> Future<Result<bool>>;

    /// Bob cancels the verification request from Alice
    fn cancel_verification_request() -> Future<Result<bool>>;

    /// Bob accepts the verification request from Alice with specified methods
    fn accept_verification_request_with_methods(methods: Vec<string>) -> Future<Result<bool>>;

    /// Alice starts the SAS verification
    fn start_sas_verification() -> Future<Result<bool>>;

    /// Bob accepts the SAS verification
    fn accept_sas_verification() -> Future<Result<bool>>;

    /// Bob cancels the SAS verification
    fn cancel_sas_verification() -> Future<Result<bool>>;

    /// Alice says to Bob that SAS verification matches and vice versa
    fn confirm_sas_verification() -> Future<Result<bool>>;

    /// Alice says to Bob that SAS verification doesn't match and vice versa
    fn mismatch_sas_verification() -> Future<Result<bool>>;

    /// Alice and Bob reviews the AnyToDeviceEvent::KeyVerificationMac
    fn review_verification_mac() -> Future<Result<bool>>;
}

object VerificationEmoji {
    /// binary representation of emoji unicode
    fn symbol() -> u32;

    /// text description of emoji unicode
    fn description() -> string;
}


//   ######  ########  ######   ######  ####  #######  ##    ##  ######  
//  ##    ## ##       ##    ## ##    ##  ##  ##     ## ###   ## ##    ## 
//  ##       ##       ##       ##        ##  ##     ## ####  ## ##       
//   ######  ######    ######   ######   ##  ##     ## ## ## ##  ######  
//        ## ##             ##       ##  ##  ##     ## ##  ####       ## 
//  ##    ## ##       ##    ## ##    ##  ##  ##     ## ##   ### ##    ## 
//   ######  ########  ######   ######  ####  #######  ##    ##  ######  



object SessionManager {
    fn all_sessions() -> Future<Result<Vec<DeviceRecord>>>;

    /// Force to logout another devices
    /// Authentication is required to do so
    fn delete_devices(dev_ids: Vec<string>, username: string, password: string) -> Future<Result<bool>>;

    /// Trigger verification of another device
    fn request_verification(dev_id: string) -> Future<Result<bool>>;
}

//  ########  ######## ##     ## ####  ######  ########  ######  
//  ##     ## ##       ##     ##  ##  ##    ## ##       ##    ## 
//  ##     ## ##       ##     ##  ##  ##       ##       ##       
//  ##     ## ######   ##     ##  ##  ##       ######    ######  
//  ##     ## ##        ##   ##   ##  ##       ##             ## 
//  ##     ## ##         ## ##    ##  ##    ## ##       ##    ## 
//  ########  ########    ###    ####  ######  ########  ######  



/// Deliver devices new event from rust to flutter
object DeviceNewEvent {
    /// get device id
    fn device_id() -> DeviceId;

    /// Request verification to any devices of user
    fn request_verification_to_user() -> Future<Result<bool>>;

    /// Request verification to specific device
    fn request_verification_to_device(dev_id: string) -> Future<Result<bool>>;

    /// Request verification to any devices of user with methods
    fn request_verification_to_user_with_methods(methods: Vec<string>) -> Future<Result<bool>>;

    /// Request verification to specific device with methods
    fn request_verification_to_device_with_methods(dev_id: string, methods: Vec<string>) -> Future<Result<bool>>;
}

/// Deliver devices changed event from rust to flutter
object DeviceChangedEvent {
    /// get device id
    fn device_id() -> DeviceId;

}

/// Provide various device infos
object DeviceRecord {
    /// get the id of this device
    fn device_id() -> DeviceId;

    /// get the display name of this device
    fn display_name() -> Option<string>;

    /// last seen ip of this device
    fn last_seen_ip() -> Option<string>;

    /// last seen timestamp of this device in milliseconds
    fn last_seen_ts() -> Option<u64>;

    /// whether it was verified
    fn is_verified() -> bool;

    /// whether it is active
    fn is_active() -> bool;
    /// whether it is this session
    fn is_me() -> bool;
}
