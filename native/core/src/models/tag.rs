use super::Color;

#[derive(Clone)]
pub struct Tag {
    pub(crate) title: String,
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
