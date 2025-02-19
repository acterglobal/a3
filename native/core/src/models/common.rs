use matrix_sdk_base::ruma::events::room::message::TextMessageEventContent;

pub struct TextMessageContent {
    inner: TextMessageEventContent,
}

impl TextMessageContent {
    pub fn body(&self) -> String {
        self.inner.body.clone()
    }

    pub fn formatted(&self) -> Option<String> {
        self.inner.formatted.clone().map(|f| f.body)
    }
}

impl From<TextMessageEventContent> for TextMessageContent {
    fn from(inner: TextMessageEventContent) -> Self {
        TextMessageContent { inner }
    }
}
