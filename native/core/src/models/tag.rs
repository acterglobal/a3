use super::Color;

#[cfg(feature = "with-mocks")]
use fake::{
    Dummy, Fake,
    faker::lorem::en::Word,
};
#[cfg(feature = "with-mocks")]
use super::mocks::ColorFaker;


#[cfg_attr(feature = "with-mocks", derive(Dummy))]
#[derive(Clone)]
pub struct Tag {
    #[cfg_attr(feature = "with-mocks", dummy(faker="Word()"))]
    pub(crate) title: String,
    #[cfg_attr(feature = "with-mocks", dummy(faker="ColorFaker"))]
    pub(crate) color: Option<Color>,
}

impl Tag {

    pub fn title(&self) -> String {
        self.title.clone()
    }

    pub fn hash_tag(&self) -> String {
        self.title.to_lowercase()
    }

    pub fn color(&self) -> Option<Color> {
        self.color.clone()
    }
}