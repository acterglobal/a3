use acter_core::events::{Icon, LabelDetails, LabelDetailsBuilder};

#[derive(Clone, Debug)]
pub struct Label {
    inner: LabelDetails,
}

/// helpers for inner
impl Label {
    pub(crate) fn new(inner: LabelDetails) -> Self {
        Self { inner }
    }
    pub fn id(&self) -> String {
        self.inner.id.clone()
    }
    pub fn title(&self) -> String {
        self.inner.title.clone()
    }

    pub fn icon(&self) -> Option<Icon> {
        self.inner.icon.clone()
    }

    pub fn update_builder(&self) -> LabelDetailsBuilder {
        LabelDetailsBuilder::default()
            .id(self.id())
            .title(self.title())
            .icon(self.icon())
            .to_owned()
    }
}
