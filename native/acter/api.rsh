
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

// would this get logged?
fn would_log(target: string, level: string) -> bool;

/// Log the entry to the rust logging
fn write_log(target: string, level: string, message: string, file: Option<string>, line: Option<u32>, module_path: Option<string>);

/// Create a new client for homeserver at url with storage at data_path
fn login_new_client(base_path: string, media_cache_base_path: string, username: string, password: string, default_homeserver_name: string, default_homeserver_url: string, device_name: Option<string>) -> Future<Result<Client>>;

/// Create a new client from the restore token
fn login_with_token(base_path: string, media_cache_base_path: string, restore_token: string) -> Future<Result<Client>>;

/// Create an anonymous client connecting to the homeserver
fn guest_client(base_path: string, media_cache_base_path: string, default_homeserver_name: string, default_homeserver_url: string, device_name: Option<string>) -> Future<Result<Client>>;

/// Create a new client from the registration token
fn register_with_token(base_path: string, media_cache_base_path: string, username: string, password: string, registration_token: string, default_homeserver_name: string, default_homeserver_url: string, device_name: string) -> Future<Result<Client>>;

/// Request the registration token via email
fn request_registration_token_via_email(base_path: string, media_cache_base_path: string, username: string, default_homeserver_name: string, default_homeserver_url: string, email: string) -> Future<Result<RegistrationTokenViaEmailResponse>>;

/// Request the password change token via email
fn request_password_change_token_via_email(default_homeserver_url: string, email: string) -> Future<Result<PasswordChangeEmailTokenResponse>>;

/// Finish password reset without login
fn reset_password(default_homeserver_url: string, sid: string, client_secret: string, new_val: string) -> Future<Result<bool>>;

/// destroy the local data of a session
fn destroy_local_data(base_path: string, media_cache_base_path: Option<string>, username: string, default_homeserver_name: string) -> Future<Result<bool>>;

fn duration_from_secs(secs: u64) -> EfkDuration;

/// create size object to be used for thumbnail download
fn new_thumb_size(width: u64, height: u64) -> Result<ThumbnailSize>;

/// create a colorize builder
fn new_colorize_builder(color: Option<u32>, background: Option<u32>) -> Result<ColorizeBuilder>;

/// create a display builder
fn new_display_builder() -> DisplayBuilder;

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
    /// gives either `link`, `task`, `task-list` or `calendar-event`
    fn type_str() -> string;
    /// what type of embed action is requested_inputs
    fn embed_action_str() -> string;
    /// if this is a `task` type, what `task-list-id` does it belong to
    fn task_list_id_str() -> Option<string>;
    /// the display title of the reference
    fn title() -> Option<string>;
    /// the room display name from the preview data
    fn room_display_name() -> Option<string>;
    /// the participants count if this is a calendar event
    fn participants() -> Option<u64>;
    /// When the event starts according to the calender preview data
    fn utc_start() -> Option<UtcDateTime>;
    /// if ref is `link`, its uri
    fn uri() -> Option<string>;

    /// the via-server names for this room
    fn via_servers() -> Vec<string>;

    /// generating an internal acter:-link
    fn generate_internal_link(include_preview: bool) -> Result<string>;

    /// generating the external link
    fn generate_external_link() -> Future<Result<string>>;
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


object VecStringBuilder {
    fn add(value: string);
}

fn new_vec_string_builder() -> VecStringBuilder;

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

object OptionComposeDraft {
    /// get compose draft object
    fn draft() -> Option<ComposeDraft>;
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
    fn display_name() -> Option<string>;

    /// which rooms you are sharing with that profile
    fn shared_rooms() -> Vec<string>;
}


/// Deliver typing event from rust
object TypingEvent {
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

object ComposeDraft {
    /// plain body text, always available
    fn plain_text() -> string;

    /// formatted text
    fn html_text() -> Option<string>;

    /// event id, only valid for edit and reply states
    fn event_id() -> Option<string>;

    /// compose message state type.
    /// One of `new`, `edit`, `reply`.
    fn draft_type() -> string;
}

object RoomId {
    fn to_string() -> string;
}

object UserId {
    fn to_string() -> string;
}

object RegistrationTokenViaEmailResponse {
    fn sid() -> string;
    fn submit_url() -> Option<string>;
}

object PasswordChangeEmailTokenResponse {
    fn client_secret() -> string;
    fn sid() -> string;
    fn submit_url() -> Option<string>;
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
    fn add_reference(reference: ObjRefBuilder);

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

    /// get timestamp of this event
    fn origin_server_ts() -> u64;

    /// whether or not this user can redact this item
    fn can_redact() -> Future<Result<bool>>;

    /// get the reaction manager
    fn reactions() -> Future<Result<ReactionManager>>;

    /// get the read receipt manager
    fn read_receipts() -> Future<Result<ReadReceiptsManager>>;

    /// get the comment manager
    fn comments() -> Future<Result<CommentsManager>>;

    /// get the internal reference object
    fn ref_details() -> Future<Result<RefDetails>>;
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



//   ######  ########  #######  ########  #### ########  ######  
//  ##    ##    ##    ##     ## ##     ##  ##  ##       ##    ## 
//  ##          ##    ##     ## ##     ##  ##  ##       ##       
//   ######     ##    ##     ## ########   ##  ######    ######  
//        ##    ##    ##     ## ##   ##    ##  ##             ## 
//  ##    ##    ##    ##     ## ##    ##   ##  ##       ##    ## 
//   ######     ##     #######  ##     ## #### ########  ######  



/// A single Slide of a Story
object StorySlide {
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

object StorySlideDraft {
    /// add reference for this slide draft
    fn add_reference(reference: ObjRefBuilder);

    /// set the color according to the colorize builder
    fn color(color: ColorizeBuilder);

    /// unset references for this slide draft
    fn unset_references();
}

/// A news entry
object Story {
    /// the slides count in this news item
    fn slides_count() -> u8;
    /// The slides belonging to this news item
    fn get_slide(pos: u8) -> Option<StorySlide>;
    /// get all slides of this news item
    fn slides() -> Vec<StorySlide>;

    /// get room id
    fn room_id() -> RoomId;

    /// get sender id
    fn sender() -> UserId;

    /// get event id
    fn event_id() -> EventId;

    /// get timestamp of this event
    fn origin_server_ts() -> u64;

    /// whether or not this user can redact this item
    fn can_redact() -> Future<Result<bool>>;

    /// get the reaction manager
    fn reactions() -> Future<Result<ReactionManager>>;

    /// get the read receipt manager
    fn read_receipts() -> Future<Result<ReadReceiptsManager>>;

    /// get the comment manager
    fn comments() -> Future<Result<CommentsManager>>;
}

object StoryDraft {
    /// create news slide draft
    fn add_slide(base_draft: StorySlideDraft) -> Future<Result<bool>>;

    /// change position of slides draft of this news entry
    fn swap_slides(from: u8, to:u8);

    /// get a copy of the news slide set for this news entry draft
    fn slides() -> Vec<StorySlideDraft>;

    /// clear slides
    fn unset_slides();

    /// create this news entry
    fn send() -> Future<Result<EventId>>;
}

object StoryUpdateBuilder {
    /// set the slides for this news entry
    fn add_slide(draft: StorySlideDraft) -> Future<Result<bool>>;

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

    /// set the display for this pin
    fn display(display: Display);
    fn unset_display();

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
    fn display() -> Option<Display>;
    /// The room this Pin belongs to
    //fn team() -> Room;

    /// the unique event ID
    //fn event_id() -> EventId;
    fn event_id_str() -> string;
    /// the room/space this item belongs to
    fn room_id_str() -> string;

    /// get the internal reference object
    fn ref_details() -> Future<Result<RefDetails>>;

    /// sender id
    fn sender() -> UserId;

    /// make a builder for updating the pin
    fn update_builder() -> Result<PinUpdateBuilder>;

    /// get informed about changes to this pin
    fn subscribe_stream() -> Stream<bool>;

    /// replace the current pin with one with the latest state
    fn refresh() -> Future<Result<ActerPin>>;

    /// whether or not this user can redact this item
    fn can_redact() -> Future<Result<bool>>;

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

    /// set the display for this pin
    fn display(display: Display);
    fn unset_display();
    fn unset_display_update();

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
    // /// locations
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

    /// whether or not this user can redact this item
    fn can_redact() -> Future<Result<bool>>;

    /// get the comments manager
    fn comments() -> Future<Result<CommentsManager>>;

    /// get the attachments manager
    fn attachments() -> Future<Result<AttachmentsManager>>;

    /// Generate a iCal as a String for sharing with others
    fn ical_for_sharing(file_name: string) -> Result<bool>;

    /// get the physical location(s) details
    fn physical_locations() -> Vec<EventLocationInfo>;

    /// get the virtual location(s) details
    fn virtual_locations() -> Vec<EventLocationInfo>;

    /// get all location details
    fn locations() -> Vec<EventLocationInfo>;


    /// get the internal reference object
    fn ref_details() -> Future<Result<RefDetails>>;

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
    fn unset_locations();

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
    /// set the physical location details for this calendar event
    fn physical_location(name: Option<string>, description: Option<string>, description_html: Option<string>, coordinates: Option<string>, uri: Option<string>) -> Result<()>;
    /// set the virtual location details for this calendar event
    fn virtual_location(name: Option<string>, description: Option<string>, description_html: Option<string>, uri: string) -> Result<()>;


    /// create this calendar event
    fn send() -> Future<Result<EventId>>;
}

object EventLocationInfo {
    /// either of `Physical` or `Virtual`
    fn location_type() -> string;
    /// get the name of location
    fn name() -> Option<string>;
    /// get the location description
    fn description() -> Option<TextMessageContent>;
    /// geo uri for the location
    fn coordinates() -> Option<string>;
    /// an online link for the location
    fn uri() -> Option<string>;
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

    /// get Yes/Maybe/No or None for the user’s own status
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


//  ########  ########    ###     ######  ######## ####  #######  ##    ## 
//  ##     ## ##         ## ##   ##    ##    ##     ##  ##     ## ###   ## 
//  ##     ## ##        ##   ##  ##          ##     ##  ##     ## ####  ## 
//  ########  ######   ##     ## ##          ##     ##  ##     ## ## ## ## 
//  ##   ##   ##       ######### ##          ##     ##  ##     ## ##  #### 
//  ##    ##  ##       ##     ## ##    ##    ##     ##  ##     ## ##   ### 
//  ##     ## ######## ##     ##  ######     ##    ####  #######  ##    ## 


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

    /// remove the reaction using symbol key
    fn redact_reaction(sender_id: string, key: string, reason: Option<string>, txn_id: Option<string>) -> Future<Result<EventId>>;

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


//  ########  ########    ###    ########     ########  ########  ######  ######## #### ########  ########  ######  
//  ##     ## ##         ## ##   ##     ##    ##     ## ##       ##    ## ##        ##  ##     ##    ##    ##    ## 
//  ##     ## ##        ##   ##  ##     ##    ##     ## ##       ##       ##        ##  ##     ##    ##    ##       
//  ########  ######   ##     ## ##     ##    ########  ######   ##       ######    ##  ########     ##     ######  
//  ##   ##   ##       ######### ##     ##    ##   ##   ##       ##       ##        ##  ##           ##          ## 
//  ##    ##  ##       ##     ## ##     ##    ##    ##  ##       ##    ## ##        ##  ##           ##    ##    ## 
//  ##     ## ######## ##     ## ########     ##     ## ########  ######  ######## #### ##           ##     ######  



object ReadReceiptsManager {
    /// mark this as read for the others in the room to know
    fn announce_read() -> Future<Result<bool>>;

    /// total of users that announced they had seen this
    fn read_count() -> u32;

    /// whether I have already marked this as read, publicly or privately
    fn read_by_me() -> bool;

    /// get informed about changes to this manager
    fn subscribe_stream() -> Stream<bool>;

    /// reload this manager
    fn reload() -> Future<Result<ReadReceiptsManager>>;

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
    /// one of NotSentYet/SendingFailed/Cancelled/Sent
    fn state() -> string;

    /// gives error value for SendingFailed only
    fn error() -> Option<string>;

    /// gives event id for Sent only
    fn event_id() -> Option<EventId>;

    // allows you to cancel a local echo
    fn abort() -> Future<Result<bool>>;
}

/// A room Message metadata and content
object RoomEventItem {
    /// The User, who sent that event
    fn sender() -> string;

    /// Send state of the message to server
    /// valid only when initialized from timeline event item
    fn send_state() -> Option<EventSendState>;

    /// the server receiving timestamp in milliseconds
    fn origin_server_ts() -> u64;

    /// one of Message/Redaction/UnableToDecrypt/FailedToParseMessageLike/FailedToParseState
    fn event_type() -> string;

    /// ID of this event
    fn event_id() -> Option<string>;

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

    /// Unique ID of this event
    fn unique_id() -> string;

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

    /// whether to have avatar
    fn has_avatar() -> bool;

    /// get the binary data of avatar
    /// if thumb size is given, avatar thumbnail is returned
    /// if thumb size is not given, avatar file is returned
    fn avatar(thumb_size: Option<ThumbnailSize>) -> Future<Result<OptionBuffer>>;

    /// get the display name
    fn display_name() -> Future<Result<OptionString>>;

    /// Whether new updates have been received for this room
    fn subscribe_to_updates() -> Stream<bool>;

    /// whether this is a Space
    fn is_space() -> bool;

    /// the JoinRule as a String
    fn join_rule_str() -> string;

    /// if set to restricted or restricted_knock the rooms this is restricted to
    fn restricted_room_ids_str() -> Vec<string>;

    /// set the join rule.
    fn set_join_rule(join_rule_builder: JoinRuleBuilder) -> Future<Result<bool>>;

    /// whether we are part of this room
    fn is_joined() -> bool;

    /// get the room profile that contains avatar and display name
    fn space_relations() -> Future<Result<SpaceRelations>>;

    /// Whether this is a direct message (in chat)
    fn is_direct() -> Future<Result<bool>>;

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

    /// Change the avatar of the room
    fn upload_avatar(uri: string) -> Future<Result<MxcUri>>;

    /// Remove the avatar of the room
    fn remove_avatar() -> Future<Result<EventId>>;

    /// what is the description / topic
    fn topic() -> Option<string>;

    /// set description / topic of the room
    fn set_topic(topic: string) -> Future<Result<EventId>>;

    /// set name of the room
    fn set_name(name: string) -> Future<Result<EventId>>;

    /// leave this room
    fn leave() -> Future<Result<bool>>;

    /// user settings for this room
    fn user_settings() -> Future<Result<UserRoomSettings>>;
}

object UserRoomSettings {

    /// whether or not the user has already seen the suggested
    /// children
    fn has_seen_suggested() -> bool;

    /// Set the value of `has_seen_suggested` for this room
    fn set_has_seen_suggested(newValue: bool) -> Future<Result<bool>>;

    /// whether or not the user wants to include this in the 
    /// calendar sync
    fn include_cal_sync() -> bool;

    /// Set the value of `include_cal_sync` for this room
    fn set_include_cal_sync(newValue: bool) -> Future<Result<bool>>;

    /// Trigger when this object needs to be refreshed
    fn subscribe_stream() -> Stream<bool>;
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

object MsgDraft {

    /// add a user mention
    fn add_mention(user_id: string) -> Result<MsgDraft>;

    /// whether to mention the entire room
    fn add_room_mention(mention: bool) -> Result<MsgDraft>;

    /// available for only image/audio/video/file
    fn mimetype(value: string) -> MsgDraft;

    /// available for only image/audio/video/file
    fn size(value: u64) -> MsgDraft;

    /// available for only image/video
    fn width(value: u64) -> MsgDraft;

    /// available for only image/video
    fn height(value: u64) -> MsgDraft;

    /// available for only audio/video
    fn duration(value: u64) -> MsgDraft;

    /// available for only image/video
    fn blurhash(value: string) -> MsgDraft;

    /// Provide the file system path to a static thumbnail
    /// for this media to be read and shared upon sending
    ///
    /// available for only image/video/file/location
    fn thumbnail_file_path(value: string) -> MsgDraft;

    /// available for only image/video/file/location
    fn thumbnail_info(width: Option<u64>, height: Option<u64>, mimetype: Option<string>, size: Option<u64>) -> MsgDraft;

    /// available for only file
    fn filename(value: string) -> MsgDraft;

    /// available for only location
    fn geo_uri(value: string) -> MsgDraft;

    /// convert this into a NewsSlideDraft;
    fn into_news_slide_draft() -> NewsSlideDraft;

    /// convert this into a StorySlideDraft;
    fn into_story_slide_draft() -> StorySlideDraft;
}

/// Timeline with Room Events
object TimelineStream {
    /// Fires whenever new diff found
    fn messages_stream() -> Stream<RoomMessageDiff>;

    /// get the specific message identified by the event_id
    fn get_message(event_id: string) -> Future<Result<RoomMessage>>;

    /// Get the next count messages backwards, and return whether it reached the end
    fn paginate_backwards(count: u16) -> Future<Result<bool>>;

    /// send message using draft
    fn send_message(draft: MsgDraft) -> Future<Result<bool>>;

    /// modify message using draft
    fn edit_message(event_id: string, draft: MsgDraft) -> Future<Result<bool>>;

    /// send reply to event
    fn reply_message(event_id: string, draft: MsgDraft) -> Future<Result<bool>>;

    /// send single receipt
    /// receipt_type: FullyRead | Read | ReadPrivate
    /// thread: Main | Unthreaded
    fn send_single_receipt(receipt_type: string, thread: string, event_id: string) -> Future<Result<bool>>;

    /// send 3 types of receipts at once
    /// full_read: optional event id
    /// public_read_receipt: optional event id
    /// private_read_receipt: optional event id
    fn send_multiple_receipts(full_read: Option<string>, public_read_receipt: Option<string>, private_read_receipt: Option<string>) -> Future<Result<bool>>;

    /// Mark this room as read.
    /// user_triggered indicate whether that was issued by the user actively
    /// (e.g. by pushing a button) or implicitly upon smart read tracking
    /// Returns a boolean indicating if we sent the request or not.
    fn mark_as_read(user_triggered: bool) -> Future<Result<bool>>;

    /// send reaction to event
    /// if sent twice, reaction is redacted
    fn toggle_reaction(event_id: string, key: string) -> Future<Result<bool>>;
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
    fn space_relations() -> Future<Result<SpaceRelations>>;

    /// Change the avatar of the room
    fn upload_avatar(uri: string) -> Future<Result<MxcUri>>;

    /// Remove the avatar of the room
    fn remove_avatar() -> Future<Result<EventId>>;

    /// what is the description / topic
    fn topic() -> Option<string>;

    /// set the name of the chat
    fn set_name(name: string) -> Future<Result<EventId>>;

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

    /// how many unread notifications for this chat
    fn num_unread_notification_count() -> u64;

    /// how many unread messages for this chat
    fn num_unread_messages() -> u64;

    /// how many unread mentions for this chat
    fn num_unread_mentions() -> u64;

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

    /// is this a bookmarked chat
    fn is_bookmarked() -> bool;

    /// set this a bookmarked chat
    fn set_bookmarked(is_bookmarked: bool) -> Future<Result<bool>>;

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
    /// it’s the callers job to ensure the person has the privileges to
    /// redact that content.
    fn redact_content(event_id: string, reason: Option<string>) -> Future<Result<EventId>>;

    fn is_joined() -> bool;

    /// compose message state of the room
    fn msg_draft() -> Future<Result<OptionComposeDraft>>;

    /// save composed message state of the room
    fn save_msg_draft(text: string, html: Option<string>, draft_type: string, event_id: Option<string>) -> Future<Result<bool>>;

    /// clear composed message state of the room
    fn clear_msg_draft() -> Future<Result<bool>>;

    /// get the internal reference object, defined in Room
    fn ref_details() -> Future<Result<RefDetails>>;
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
    /// what is the comment’s content
    fn msg_content() -> MsgContent;
    /// create a draft builder to reply to this comment
    fn reply_builder() -> CommentDraft;

    /// whether or not this user can redact this item
    fn can_redact() -> Future<Result<bool>>;
}

/// Reference to the comments section of a particular item
object CommentsManager {
    /// Get the list of comments (in arrival order)
    fn comments() -> Future<Result<Vec<Comment>>>;

    /// String representation of the room id this comments manager is in
    fn room_id_str() -> string;

    /// String of the id of the object the comments are managed for
    fn object_id_str() -> string;

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
    /// display name, either filename or given by the user, if found
    fn name() -> Option<string>;
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
    /// if this is a media, hand over its details
    fn msg_content() -> Option<MsgContent>;
    /// if this is a reference, here are the details
    fn ref_details() -> Option<RefDetails>;

    /// if this is a link, this contains the URI/Link/URL
    fn link() -> Option<string>;

    /// if this is a media, hand over the data
    /// if thumb size is given, media thumbnail is returned
    /// download media (image/audio/video/file/location) to specified path
    /// if thumb size is given, media thumbnail is returned
    /// if thumb size is not given, media file is returned
    fn download_media(thumb_size: Option<ThumbnailSize>, dir_path: string) -> Future<Result<OptionString>>;

    /// get the path that media (image/audio/video/file) was saved
    /// return None when never downloaded
    fn media_path(is_thumb: bool) -> Future<Result<OptionString>>;

    /// whether or not this user can redact this item
    fn can_redact() -> Future<Result<bool>>;
}

/// Reference to the attachments section of a particular item
object AttachmentsManager {
    /// the room this attachments manager lives in
    fn room_id_str() -> string;

    /// the id of the object whose attachments are managed
    fn object_id_str() -> string;

    /// Whether or not the current user can post, edit and delete
    /// attachments in this manager
    fn can_edit_attachments() -> bool;

    /// Get the list of attachments (in arrival order)
    fn attachments() -> Future<Result<Vec<Attachment>>>;

    /// Does this item have any attachments?
    fn has_attachments() -> bool;

    /// How many attachments does this item have
    fn attachments_count() -> u32;

    /// create attachment for given msg draft
    fn content_draft(base_draft: MsgDraft) -> Future<Result<AttachmentDraft>>;

    /// create attachment for given link draft
    fn link_draft(url: string, name: Option<string>) -> Future<Result<AttachmentDraft>>;

    /// create attachment for given ref_details
    fn reference_draft(details: RefDetails) -> Future<Result<AttachmentDraft>>;

    /// inform about the changes to this manager
    fn reload() -> Future<Result<AttachmentsManager>>;

    /// redact attachment
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

    /// What display options are given?
    fn display() -> Option<Display>;

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

    /// whether or not this user can redact this item
    fn can_redact() -> Future<Result<bool>>;

    /// get the comments manager for this task
    fn comments() -> Future<Result<CommentsManager>>;

    /// get the attachments manager
    fn attachments() -> Future<Result<AttachmentsManager>>;
}

object TaskUpdateBuilder {
    /// set the title for this task
    fn title(title: string);
    fn unset_title_update();

    /// set the description for this task list
    fn description_text(text: string);
    /// set description html text
    fn description_html(body: string, html_body: string);

    fn unset_description();
    fn unset_description_update();

    /// set the sort order for this task list
    fn sort_order(sort_order: u32);
    fn unset_sort_order_update();

    /// set the display of the update
    fn display(display: Display);
    fn unset_display();
    fn unset_display_update();

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
    /// set description html text
    fn description_html(body: string, html_body: string);

    fn unset_description();

    /// set the sort order for this task
    fn sort_order(sort_order: u32);

    /// set the disply options for this task
    fn display(display: Display);
    fn unset_display();

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

    /// What display options are given?
    fn display() -> Option<Display>;

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

    /// whether or not this user can redact this item
    fn can_redact() -> Future<Result<bool>>;

    /// the space this TaskList belongs to
    fn space() -> Space;

    /// the id of the space this TaskList belongs to
    fn space_id_str() -> string;

    /// get the internal reference object
    fn ref_details() -> Future<Result<RefDetails>>;

    /// get the comments manager
    fn comments() -> Future<Result<CommentsManager>>;

    /// get the attachments manager
    fn attachments() -> Future<Result<AttachmentsManager>>;
}

object TaskListDraft {
    /// set the name for this task list
    fn name(name: string);

    /// set the description for this task list
    fn description_text(text: string);
    fn description_markdown(text: string);
    /// set description html text
    fn description_html(body: string, html_body: string);

    fn unset_description();

    /// set the sort order for this task list
    fn sort_order(sort_order: u32);

    /// set the display for this task list
    fn display(display: Display);
    fn unset_display();

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
    /// set description html text
    fn description_html(body: string, html_body: string);

    fn unset_description();
    fn unset_description_update();

    /// set the sort order for this task list
    fn sort_order(sort_order: u32);

    /// set the display for this task list
    fn display(display: Display);
    fn unset_display();
    fn unset_display_update();

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

    /// is this a suggested room?
    fn suggested() -> bool;

    /// get the binary data of avatar
    /// if thumb size is given, avatar thumbnail is returned
    /// if thumb size is not given, avatar file is returned
    fn get_avatar(thumb_size: Option<ThumbnailSize>) -> Future<Result<OptionBuffer>>;
    /// recommended server to try to join via
    fn via_server_names() -> Vec<string>;
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
    fn query_hierarchy() -> Future<Result<Vec<SpaceHierarchyRoomInfo>>>;
}

object RoomPowerLevels {
    fn news() -> Option<i64>;
    fn news_key() -> string;

    fn stories() -> Option<i64>;
    fn stories_key() -> string;

    fn events() -> Option<i64>;
    fn events_key() -> string;

    fn pins() -> Option<i64>;
    fn pins_key() -> string;

    fn tasks() -> Option<i64>;
    fn tasks_key() -> string;

    fn task_lists() -> Option<i64>;
    fn task_lists_key() -> string;

    fn rsvp() -> Option<i64>;
    fn rsvp_key() -> string;

    fn comments() -> Option<i64>;
    fn comments_key() -> string;

    fn attachments() -> Option<i64>;
    fn attachments_key() -> string;

    // -- defaults

    fn events_default() -> i64;
    fn users_default() -> i64;
    fn max_power_level() -> i64;

    fn kick() -> i64;
    fn ban() -> i64;
    fn redact() -> i64;
    fn invite() -> i64;
}

object SimpleOnOffSetting {
    fn active() -> bool;
}

object SimpleOnOffSettingBuilder {
    fn active(active: bool);
    fn build() -> Result<SimpleOnOffSetting>;
}


object SimpleSettingWithTurnOff {
    fn active() -> bool;
}

object SimpleSettingWithTurnOffBuilder {
    fn active(active: bool);
    fn build() -> Result<SimpleSettingWithTurnOff>;
}


object NewsSettings {
    fn active() -> bool;
    fn updater() -> SimpleSettingWithTurnOffBuilder;
}

object StoriesSettings {
    fn active() -> bool;
    fn updater() -> SimpleOnOffSettingBuilder;
}

object TasksSettings {
    fn active() -> bool;
    fn updater() -> SimpleOnOffSettingBuilder;
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
    fn stories() -> StoriesSettings;
    fn pins() -> PinsSettings;
    fn events() -> EventsSettings;
    fn tasks() -> TasksSettings;
    fn update_builder() -> ActerAppSettingsBuilder;
}

object ActerAppSettingsBuilder {
    fn news(news: Option<SimpleSettingWithTurnOff>);
    fn stories(tasks: Option<SimpleOnOffSetting>);
    fn pins(pins: Option<SimpleSettingWithTurnOff>);
    fn events(events: Option<SimpleSettingWithTurnOff>);
    fn tasks(tasks: Option<SimpleOnOffSetting>);
}



//     ###     ######  ######## #### ##     ## #### ######## #### ########  ######  
//    ## ##   ##    ##    ##     ##  ##     ##  ##     ##     ##  ##       ##    ## 
//   ##   ##  ##          ##     ##  ##     ##  ##     ##     ##  ##       ##       
//  ##     ## ##          ##     ##  ##     ##  ##     ##     ##  ######    ######  
//  ######### ##          ##     ##   ##   ##   ##     ##     ##  ##             ## 
//  ##     ## ##    ##    ##     ##    ## ##    ##     ##     ##  ##       ##    ## 
//  ##     ##  ######     ##    ####    ###    ####    ##    #### ########  ######  

object MembershipChange {
    /// user_id of the member that has changed
    fn user_id_str() -> string;

    /// avatar_url of the member that has changed
    fn avatar_url() -> Option<string>;

    /// display_name of the member that has changed
    fn display_name() -> Option<string>;

    /// reason if any was provided
    fn reason() -> Option<string>;
}

object ActivityObject {
    fn type_str() -> string;
    fn object_id_str() -> string;
    fn title() -> Option<string>;
    fn emoji() -> string;
}

object Activity {
    // generic

    /// the event_id as a string
    fn event_id_str() -> string;
    /// the sender of this event as a string
    fn sender_id_str() -> string;

    /// the server receiving timestamp in milliseconds
    fn origin_server_ts() -> u64;

    /// the room_id of this event
    fn room_id_str() -> string;

    /// the type of this activity as a string
    /// e.g. invited, invitationAccepted
    fn type_str() -> string;

    /// the details of this membership change activity
    fn membership_change() -> Option<MembershipChange>;

    /// if the added information is a reference
    fn ref_details() -> Option<RefDetails>;

    /// where to route to for the details of this activity
    fn target_url() -> string;

    /// the object this activity happened on, if any
    fn object() -> Option<ActivityObject>;

    /// content of this activity, if any
    fn msg_content() -> Option<MsgContent>;

    /// reaction specific: the reaction key used
    fn reaction_key() -> Option<string>;

    /// the date on eventDateChange (started or ended) or taskDueDateChane
    fn new_date() -> Option<UtcDateTime>;

}

object Activities {
    /// get the activity ids from offset to limit for this activities listing
    fn get_ids(offset: u32, limit: u32) -> Future<Result<Vec<string>>>;

    /// Receive an update when a the activities stream has changed
    fn subscribe_stream() -> Stream<bool>;
}



//  ########   #######   #######  ##     ##    ########  ########  ######## ##     ## #### ######## ##      ## 
//  ##     ## ##     ## ##     ## ###   ###    ##     ## ##     ## ##       ##     ##  ##  ##       ##  ##  ## 
//  ##     ## ##     ## ##     ## #### ####    ##     ## ##     ## ##       ##     ##  ##  ##       ##  ##  ## 
//  ########  ##     ## ##     ## ## ### ##    ########  ########  ######   ##     ##  ##  ######   ##  ##  ## 
//  ##   ##   ##     ## ##     ## ##     ##    ##        ##   ##   ##        ##   ##   ##  ##       ##  ##  ## 
//  ##    ##  ##     ## ##     ## ##     ##    ##        ##    ##  ##         ## ##    ##  ##       ##  ##  ## 
//  ##     ##  #######   #######  ##     ##    ##        ##     ## ########    ###    #### ########  ###  ###  


object RoomPreview {
    fn room_id_str() -> string;
    fn name() -> Option<string>;
    fn topic() -> Option<string>;
    fn avatar_url_str() -> Option<string>;
    fn canonical_alias_str() -> Option<string>;
    fn room_type_str() -> string;
    fn join_rule_str() -> string;
    fn state_str() -> string;
    fn is_direct() -> Option<bool>;
    fn is_world_readable() -> Option<bool>;
    fn has_avatar() -> bool;
    fn avatar(thumb_size: Option<ThumbnailSize>) -> Future<Result<OptionBuffer>>;
}



//   ######     ###    ######## ########  ######    #######  ########  ##    ## 
//  ##    ##   ## ##      ##    ##       ##    ##  ##     ## ##     ##  ##  ##  
//  ##        ##   ##     ##    ##       ##        ##     ## ##     ##   ####   
//  ##       ##     ##    ##    ######   ##   #### ##     ## ########     ##    
//  ##       #########    ##    ##       ##    ##  ##     ## ##   ##      ##    
//  ##    ## ##     ##    ##    ##       ##    ##  ##     ## ##    ##     ##    
//   ######  ##     ##    ##    ########  ######    #######  ##     ##    ##    


object Category {
    fn title() -> string;
    fn entries() -> Vec<string>;
    fn display() -> Option<Display>;
    fn update_builder() -> CategoryBuilder;
}

object CategoryBuilder {
    fn title(title: string);
    fn clear_entries();
    fn add_entry(entry: string);
    fn display(display: Display);
    fn unset_display();
    fn build() -> Result<Category>;
}


object Categories {
    fn categories() -> Vec<Category>;
    fn new_category_builder() -> CategoryBuilder;
    fn update_builder() -> CategoriesBuilder;
}

object CategoriesBuilder {
    fn add(cat: Category);
    fn clear();
}


//  ########  ####  ######  ########  ##          ###    ##    ## 
//  ##     ##  ##  ##    ## ##     ## ##         ## ##    ##  ##  
//  ##     ##  ##  ##       ##     ## ##        ##   ##    ####   
//  ##     ##  ##   ######  ########  ##       ##     ##    ##    
//  ##     ##  ##        ## ##        ##       #########    ##    
//  ##     ##  ##  ##    ## ##        ##       ##     ##    ##    
//  ########  ####  ######  ##        ######## ##     ##    ##    


object Display {
    fn icon_type_str() -> Option<string>;
    fn icon_str() -> Option<string>;
    fn color() -> Option<u32>;
    fn update_builder() -> DisplayBuilder;
}

object DisplayBuilder {
    fn icon(type: string, value: string);
    fn unset_icon();
    fn color(color: u32);
    fn unset_color();
    fn build() -> Result<Display>;
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
    fn space_relations() -> Future<Result<SpaceRelations>>;

    /// Whether this space is a child of the given space
    fn is_child_space_of(room_id: string) -> Future<bool>;

    /// add the following as a child space and return event id of that event
    /// flag as suggested or not
    fn add_child_room(room_id: string, suggested: bool) -> Future<Result<string>>;

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

    /// is this a bookmarked space
    fn is_bookmarked() -> bool;

    /// set this a bookmarked space
    fn set_bookmarked(is_bookmarked: bool) -> Future<Result<bool>>;

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

    /// task list draft builder
    fn task_list_draft() -> Result<TaskListDraft>;

    /// get latest news
    fn latest_news_entries(count: u32) -> Future<Result<Vec<NewsEntry>>>;

    /// get latest stories
    fn latest_stories(count: u32) -> Future<Result<Vec<Story>>>;

    /// get all calendar events
    fn calendar_events() -> Future<Result<Vec<CalendarEvent>>>;

    /// create calendar event draft
    fn calendar_event_draft() -> Result<CalendarEventDraft>;

    /// create news draft
    fn news_draft() -> Result<NewsEntryDraft>;

    /// create story draft
    fn story_draft() -> Result<StoryDraft>;

    /// the pins of this Space
    fn pins() -> Future<Result<Vec<ActerPin>>>;

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

    /// update the power level for a regular room feature
    fn update_regular_power_levels(feature: string, level: i32) -> Future<Result<bool>>;

    /// report an event from this room
    /// score - The score to rate this content as where -100 is most offensive and 0 is inoffensive (optional).
    /// reason - The reason for the event being reported (optional).
    fn report_content(event_id: string, score: Option<i32>, reason: Option<string>) -> Future<Result<bool>>;

    /// redact an event from this room
    /// reason - The reason for the event being reported (optional).
    /// it’s the callers job to ensure the person has the privileges to
    /// redact that content.
    fn redact_content(event_id: string, reason: Option<string>) -> Future<Result<EventId>>;


    /// Get the categories for a specific key.
    /// currently supported: spaces, chats
    fn categories(key: string) -> Future<Result<Categories>>;

    /// Set the categories for a specific key
    fn set_categories(key: string, categories: CategoriesBuilder) -> Future<Result<bool>>;

    /// get the internal reference object, defined in Room
    fn ref_details() -> Future<Result<RefDetails>>;
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
    CanPostStories,
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
    CanUpdateJoinRule,
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

    /// RoomId this member is attachd to
    fn room_id_str() -> string;

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

    /// kick this member from this room
    fn kick(msg: Option<string>) -> Future<Result<bool>>;

    /// ban this member from this room
    fn ban(msg: Option<string>) -> Future<Result<bool>>;

    /// remove the member ban from this room
    fn unban(msg: Option<string>) -> Future<Result<bool>>;
}


//     ###    ########  ########      ######  ######## ######## ######## #### ##    ##  ######    ######  
//    ## ##   ##     ## ##     ##    ##    ## ##          ##       ##     ##  ###   ## ##    ##  ##    ## 
//   ##   ##  ##     ## ##     ##    ##       ##          ##       ##     ##  ####  ## ##        ##       
//  ##     ## ########  ########      ######  ######      ##       ##     ##  ## ## ## ##   ####  ######  
//  ######### ##        ##                 ## ##          ##       ##     ##  ##  #### ##    ##        ## 
//  ##     ## ##        ##           ##    ## ##          ##       ##     ##  ##   ### ##    ##  ##    ## 
//  ##     ## ##        ##            ######  ########    ##       ##    #### ##    ##  ######    ######  




object ActerUserAppSettings {
    /// either of 'always', 'never' or 'wifiOnly'
    fn auto_download_chat() -> Option<string>;

    /// whether to allow sending typing notice of users
    fn typing_notice() -> Option<bool>;

    /// whether to automatically subscribe to push notifications
    /// once interacted
    fn auto_subscribe_on_activity() -> bool;

    /// update the builder with the current settings

    /// if you intend to change anything
    fn update_builder() -> ActerUserAppSettingsBuilder;
}

object ActerUserAppSettingsBuilder {
    /// either of 'always', 'never' or 'wifiOnly'
    fn auto_download_chat(value: string);

    /// whether to allow sending typing notice of users
    fn typing_notice(value: bool);

    /// set whether to automatically subscribe to push notifications
    /// once interacted
    fn auto_subscribe_on_activity(value: bool);

    /// submit this updated version
    fn send() -> Future<Result<bool>>;
}



//     ###     ######   ######   #######  ##     ## ##    ## ######## 
//    ## ##   ##    ## ##    ## ##     ## ##     ## ###   ##    ##    
//   ##   ##  ##       ##       ##     ## ##     ## ####  ##    ##    
//  ##     ## ##       ##       ##     ## ##     ## ## ## ##    ##    
//  ######### ##       ##       ##     ## ##     ## ##  ####    ##    
//  ##     ## ##    ## ##    ## ##     ## ##     ## ##   ###    ##    
//  ##     ##  ######   ######   #######   #######  ##    ##    ##    



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

    /// the current app settings
    fn acter_app_settings() -> Future<Result<ActerUserAppSettings>>;

    /// listen to updates to the app settings
    fn subscribe_app_settings_stream() -> Stream<bool>;

    /// deactivate the account. This can not be reversed. The username will
    /// be blocked from any future usage, all personal data will be removed.
    fn deactivate(password: string) -> Future<Result<bool>>;

    /// change password
    fn change_password(old_val: string, new_val: string) -> Future<Result<bool>>;

    /// get email addresses from third party identifier
    fn confirmed_email_addresses() -> Future<Result<Vec<string>>>;

    /// get email addresses that were registered
    fn requested_email_addresses() -> Future<Result<Vec<string>>>;

    /// Requests token via email and add email address to third party identifier.
    /// If password is not enough complex, homeserver may reject this request.
    fn request_3pid_management_token_via_email(email_address: string) -> Future<Result<ThreePidEmailTokenResponse>>;

    /// get the array of registered 3pid on the homeserver for this account
    fn external_ids() -> Future<Result<Vec<ExternalId>>>;

    /// find out session id that is related with email address and add email address to account using session id & password
    fn try_confirm_email_status(email_address: string, password: string) -> Future<Result<bool>>;

    /// Submit token to finish email register
    fn submit_token_from_email(email_address: string, token: string, password: string) -> Future<Result<bool>>;

    /// Remove email address from confirmed list or unconfirmed list
    fn remove_email_address(email_address: string) -> Future<Result<bool>>;

    /// Get the Bookmarks manager
    fn bookmarks() -> Future<Result<Bookmarks>>;
}

object ExternalId {
    /// get address of 3pid
    fn address() -> string;

    /// get medium of 3pid
    /// one of [email, msisdn]
    fn medium() -> string;

    /// get time when the homeserver associated the third party identifier with the user
    fn added_at() -> u64;

    /// get time when the identifier was validated by the identity server
    fn validated_at() -> u64;
}

object ThreePidEmailTokenResponse {
    /// get session id
    fn sid() -> string;

    /// get submit url
    fn submit_url() -> Option<string>;

    /// get client secret
    fn client_secret() -> string;
}


//  ########   #######   #######  ##    ## ##     ##    ###    ########  ##    ##  ######  
//  ##     ## ##     ## ##     ## ##   ##  ###   ###   ## ##   ##     ## ##   ##  ##    ## 
//  ##     ## ##     ## ##     ## ##  ##   #### ####  ##   ##  ##     ## ##  ##   ##       
//  ########  ##     ## ##     ## #####    ## ### ## ##     ## ########  #####     ######  
//  ##     ## ##     ## ##     ## ##  ##   ##     ## ######### ##   ##   ##  ##         ## 
//  ##     ## ##     ## ##     ## ##   ##  ##     ## ##     ## ##    ##  ##   ##  ##    ## 
//  ########   #######   #######  ##    ## ##     ## ##     ## ##     ## ##    ##  ######  


object Bookmarks {
    /// get the list of bookmarks for a specific key
    fn entries(key: string) -> Vec<string>;

    /// add the following entry to the bookmarks of key
    fn add(key: string, entry: string) -> Future<Result<bool>>;

    /// remove the following entry from the bookmarks of key
    fn remove(key: string, entry: string) -> Future<Result<bool>>;
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

    /// whether to have avatar
    fn has_avatar() -> bool;

    /// get the binary data of avatar
    /// if thumb size is given, avatar thumbnail is returned
    /// if thumb size is not given, avatar file is returned
    fn get_avatar(thumb_size: Option<ThumbnailSize>) -> Future<Result<OptionBuffer>>;
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
    fn parent() -> Option<ActivityObject>;
    fn parent_id_str() -> Option<string>;
    fn room() -> NotificationRoom;
    fn target_url() -> string;
    fn body() -> Option<MsgContent>;
    fn icon_url() -> Option<string>;
    fn thread_id() -> Option<string>;
    fn noisy() -> bool;
    fn has_image() -> bool;
    fn image() -> Future<Result<buffer<u8>>>;
    fn image_path(tmp_dir: string) -> Future<Result<string>>;

    /// if this is an invite, this the room it invites to
    fn room_invite_str() -> Option<string>;

    /// reaction specific: the reaction key used
    fn reaction_key() -> Option<string>;

    /// the date on eventDateChange (started or ended) or taskDueDateChane
    fn new_date() -> Option<UtcDateTime>;
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

    /// set the space’s visibility to either Public or Private
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

    /// attempt to join a room
    fn join_room(room_id_or_alias: string, server_names: VecStringBuilder) -> Future<Result<Room>>;

    /// Get the space that user belongs to
    fn space(room_id_or_alias: string) -> Future<Result<Space>>;

    /// Get the invitation event stream
    fn invitations_rx() -> Stream<Vec<Invitation>>;

    /// the users out of room
    fn suggested_users(room_name: Option<string>) -> Future<Result<Vec<UserProfile>>>;

    /// search the user directory
    fn search_users(search_term: string) -> Future<Result<Vec<UserProfile>>>;

    /// search the public directory for rooms
    fn search_public_room(search_term: Option<string>, server: Option<string>, room_filter: Option<string>, since: Option<string>) -> Future<Result<PublicSearchResult>>;

    /// Whether the user already verified the device
    fn verified_device(dev_id: string) -> Future<Result<bool>>;

    /// log out this client
    fn logout() -> Future<Result<bool>>;

    /// Get the verification event receiver
    fn verification_event_rx() -> Stream<VerificationEvent>;

    /// Get session manager that returns all/verified/unverified/inactive session list
    fn session_manager() -> SessionManager;

    /// Trigger verification of another device
    /// returns flow id of verification
    fn request_verification(dev_id: string) -> Future<Result<VerificationEvent>>;

    /// install verification request event handler
    fn install_request_event_handler(flow_id: string) -> Future<Result<bool>>;

    /// install sas verification event handler
    fn install_sas_event_handler(flow_id: string) -> Future<Result<bool>>;

    /// Return the event handler that new device was found or existing device was changed
    fn device_event_rx() -> Stream<DeviceEvent>;

    /// Return the typing event receiver
    fn subscribe_to_typing_event_stream(room_id: string) -> Stream<TypingEvent>;

    /// create convo
    fn create_convo(settings: CreateConvoSettings) -> Future<Result<RoomId>>;

    /// create default space
    fn create_acter_space(settings: CreateSpaceSettings) -> Future<Result<RoomId>>;

    /// listen to updates to any section
    fn subscribe_section_stream(section: string) -> Result<Stream<bool>>;

    /// listen to updates to any model
    fn subscribe_model_stream(model_id: string) -> Result<Stream<bool>>;

    /// listen to updates to objects of a model, e.g. rsvp or comments
    fn subscribe_model_objects_stream(model_id: string, sublist: string) -> Result<Stream<bool>>;

    /// listen to updates to any room parameter
    fn subscribe_model_param_stream(key: string, param: string) -> Result<Stream<bool>>;

    /// listen to updates to any room
    fn subscribe_room_stream(key: string) -> Result<Stream<bool>>;

    /// listen to updates to any room parameter
    fn subscribe_room_param_stream(key: string, param: string) -> Result<Stream<bool>>;

    /// listen to updates to a room section
    fn subscribe_room_section_stream(key: string, section: string) -> Result<Stream<bool>>;

    /// listen to updates to any event type
    fn subscribe_event_type_stream(key: string) -> Result<Stream<bool>>;

    /// listen to account data updates
    fn subscribe_account_data_stream(key: string) -> Result<Stream<bool>>;

    /// listen to account data updates of specific room
    fn subscribe_room_account_data_stream(room: string, key: string) -> Result<Stream<bool>>;

    /// Find the room or wait until it becomes available
    fn wait_for_room(key: string, timeout: Option<u8>) -> Future<Result<bool>>;

    /// Fetch the Comment or use its event_id to wait for it to come down the wire
    fn wait_for_comment(key: string, timeout: Option<u8>) -> Future<Result<Comment>>;

    /// Fetch the NewsEntry or use its event_id to wait for it to come down the wire
    fn wait_for_news(key: string, timeout: Option<u8>) -> Future<Result<NewsEntry>>;

    /// Get the latest News for the client
    fn latest_news_entries(count: u32) -> Future<Result<Vec<NewsEntry>>>;

    /// Fetch the Story or use its event_id to wait for it to come down the wire
    fn wait_for_story(key: string, timeout: Option<u8>) -> Future<Result<Story>>;

    /// Get the Stories for the client
    fn latest_stories(count: u32) -> Future<Result<Vec<Story>>>;

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

    /// super invites interface
    fn super_invites() -> SuperInvites;

    /// allow to configure notification settings
    fn notification_settings() -> Future<Result<NotificationSettings>>;

    /// the list of devices
    fn device_records(verified: bool) -> Future<Result<Vec<DeviceRecord>>>;

    /// make draft to send text plain msg
    fn text_plain_draft(body: string) -> MsgDraft;

    /// make draft to send text markdown msg
    fn text_markdown_draft(body: string) -> MsgDraft;

    /// make draft to send html marked up msg
    fn text_html_draft(html: string, plain: string) -> MsgDraft;

    /// make draft to send image msg
    fn image_draft(source: string, mimetype: string) -> MsgDraft;

    /// make draft to send audio msg
    fn audio_draft(source: string, mimetype: string) -> MsgDraft;

    /// make draft to send video msg
    fn video_draft(source: string, mimetype: string) -> MsgDraft;

    /// make draft to send file msg
    fn file_draft(source: string, mimetype: string) -> MsgDraft;

    /// make draft to send location msg
    fn location_draft(body: string, source: string) -> MsgDraft;

    /// get access to the backup manager
    fn backup_manager() -> BackupManager;

    /// Room preview
    fn room_preview(room_id_or_alias: string, server_names: VecStringBuilder) -> Future<Result<RoomPreview>>;


    /// create a link ref details
    fn new_link_ref_details(title: string, uri: string) -> Result<RefDetails>;

    /// get a specific activity
    fn activity(key: string) -> Future<Result<Activity>>;

    /// get the activities listener for a room
    fn activities_for_room(key: string) -> Result<Activities>;

    /// get the activities listener for a specific object
    fn activities_for_obj(key: string) -> Result<Activities>;
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

    /// specific object based subscriptions
    /// one of 'subscribed', 'parent' or 'none'
    fn object_push_subscription_status_str(object_id: string, sub_type: Option<string>) -> Future<Result<string>>;
    fn subscribe_object_push(object_id: string, sub_type: Option<string>) -> Future<Result<bool>>;
    fn unsubscribe_object_push(object_id: string, sub_type: Option<string>) -> Future<Result<bool>>;
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

    /// whether this is an invite to a DM
    fn is_dm() -> bool;

    /// the RoomId as a String
    fn room_id_str() -> string;

    /// get the room of this invitation
    fn room() -> Room;

    /// get the user id of this invitation sender as string
    fn sender_id_str() -> string;

    /// get the user profile that contains avatar and display name
    fn sender_profile() -> Option<UserProfile>;

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

    /// get the token info
    fn info(token: string) -> Future<Result<SuperInviteInfo>>;
}

object SuperInviteInfo {
    /// whether or not this token will create a DM with the new user
    fn create_dm() -> bool;

    /// whether or not this token has been redeemed by the caller
    fn has_redeemed() -> bool;

    /// the number of rooms that will be added - includes DM if created
    fn rooms_count() -> u32;

    /// the UserId of the inviter
    fn inviter_user_id_str() -> string;

    /// the display_name of the inviter if known
    fn inviter_display_name_str() -> Option<string>;

    /// the Avatar URl of the inviter if known
    fn inviter_avatar_url_str() -> Option<string>;
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

    /// get the internal reference object
    fn ref_details() -> RefDetails;
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
    fn flow_id() -> string;

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
    /// alternative of terminate_verification
    fn cancel_verification_request() -> Future<Result<bool>>;

    /// Bob accepts the verification request from Alice with specified method
    fn accept_verification_request_with_method(method: string) -> Future<Result<bool>>;

    /// Alice starts the SAS verification
    fn start_sas_verification() -> Future<Result<bool>>;

    /// Bob accepts the SAS verification
    fn accept_sas_verification() -> Future<Result<bool>>;

    /// Bob cancels the SAS verification
    fn cancel_sas_verification() -> Future<Result<bool>>;

    /// Alice says to Bob that SAS verification matches and vice versa
    fn confirm_sas_verification() -> Future<Result<bool>>;

    /// Alice says to Bob that SAS verification doesn’t match and vice versa
    fn mismatch_sas_verification() -> Future<Result<bool>>;
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

    /// Force to logout another device
    /// Authentication is required to do so
    fn delete_device(dev_id: string, username: string, password: string) -> Future<Result<bool>>;

    /// Trigger verification of another device
    /// returns flow id of verification
    fn request_verification(dev_id: string) -> Future<Result<string>>;

    /// Terminate verification of another device
    /// alternative of cancel_verification_request
    /// this fn is used in case without verification event
    fn terminate_verification(flow_id: string) -> Future<Result<bool>>;
}

//  ########  ######## ##     ## ####  ######  ########  ######  
//  ##     ## ##       ##     ##  ##  ##    ## ##       ##    ## 
//  ##     ## ##       ##     ##  ##  ##       ##       ##       
//  ##     ## ######   ##     ##  ##  ##       ######    ######  
//  ##     ## ##        ##   ##   ##  ##       ##             ## 
//  ##     ## ##         ## ##    ##  ##    ## ##       ##    ## 
//  ########  ########    ###    ####  ######  ########  ######  



/// Deliver devices new event from rust to flutter
object DeviceEvent {
    /// get devices that was found newly
    fn new_devices() -> Vec<string>;

    /// get devices that already existed and was just changed
    fn changed_devices() -> Vec<string>;
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



//     ########     ###     ######  ##    ## ##     ## ########     ##     ##    ###    ##    ##    ###     ######   ######## ########  
//     ##     ##   ## ##   ##    ## ##   ##  ##     ## ##     ##    ###   ###   ## ##   ###   ##   ## ##   ##    ##  ##       ##     ## 
//     ##     ##  ##   ##  ##       ##  ##   ##     ## ##     ##    #### ####  ##   ##  ####  ##  ##   ##  ##        ##       ##     ## 
//     ########  ##     ## ##       #####    ##     ## ########     ## ### ## ##     ## ## ## ## ##     ## ##   #### ######   ########  
//     ##     ## ######### ##       ##  ##   ##     ## ##           ##     ## ######### ##  #### ######### ##    ##  ##       ##   ##   
//     ##     ## ##     ## ##    ## ##   ##  ##     ## ##           ##     ## ##     ## ##   ### ##     ## ##    ##  ##       ##    ##  
//     ########  ##     ##  ######  ##    ##  #######  ##           ##     ## ##     ## ##    ## ##     ##  ######   ######## ##     ## 


/// Manage Encryption Backups
object BackupManager {

    /// Create a new backup version, encrypted with a new backup recovery key.
    fn enable() -> Future<Result<string>>;

    /// Reset the existing backup version, encrypted with a new backup recovery key.
    fn reset() -> Future<Result<string>>;

    /// Disable and delete the currently active backup.
    fn disable() -> Future<Result<bool>>;

    /// Current state as a string
    fn state_str() -> string;

    /// state as a string via a stream. Issues the current state immediately
    fn state_stream() -> Stream<string>;

    /// Open the existing secret store using the given key and import the keys
    fn recover(secret: string) -> Future<Result<bool>>;

}