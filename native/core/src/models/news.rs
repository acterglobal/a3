use  crate::events::Color;

#[cfg(feature = "with-mocks")]
use fake::{
    Dummy, Fake, Faker,
    // faker::lorem::en::Paragraph,
};

#[cfg_attr(feature = "with-mocks", derive(Dummy))]
pub struct News {
    text: Option<String>,
}

impl News{
    pub fn text(&self) -> &Option<String> {
        &self.text
    }
} 


#[cfg(feature = "with-mocks")]
pub fn gen_mocks() -> Vec<News> {
    vec![
        Faker.fake(),
        Faker.fake(),
        Faker.fake(),
        Faker.fake(),
        Faker.fake(),
        Faker.fake(),
        Faker.fake(),
    ]

}