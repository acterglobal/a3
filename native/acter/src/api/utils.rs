// copied from ruma, which - unfortunately, doesn't expose this helper
// https://github.com/ruma/ruma/blob/fec7d23cfd44266cc396f5abc08ea821dc138d6d/crates/ruma-common/src/events/room/message.rs#L937
pub fn parse_markdown(text: String) -> Option<String> {
    use pulldown_cmark::{Event, Options, Parser, Tag};

    const OPTIONS: Options = Options::ENABLE_TABLES.union(Options::ENABLE_STRIKETHROUGH);

    let mut found_first_paragraph = false;

    let parser_events: Vec<_> = Parser::new_ext(&text, OPTIONS)
        .map(|event| match event {
            Event::SoftBreak => Event::HardBreak,
            _ => event,
        })
        .collect();
    let has_markdown = parser_events.iter().any(|ref event| {
        let is_text = matches!(event, Event::Text(_));
        let is_break = matches!(event, Event::HardBreak);
        let is_first_paragraph_start = if matches!(event, Event::Start(Tag::Paragraph)) {
            if found_first_paragraph {
                false
            } else {
                found_first_paragraph = true;
                true
            }
        } else {
            false
        };
        let is_paragraph_end = matches!(event, Event::End(Tag::Paragraph));

        !is_text && !is_break && !is_first_paragraph_start && !is_paragraph_end
    });

    if !has_markdown {
        return None;
    }

    let mut html_body = String::new();
    pulldown_cmark::html::push_html(&mut html_body, parser_events.into_iter());

    Some(html_body)
}
