use  crate::events::Color;

#[cfg(feature = "with-mocks")]
use fake::{
    Dummy, Fake, Faker,
    faker::lorem::en::{
        Paragraph, Sentence
    }
};

#[cfg_attr(feature = "with-mocks", derive(Dummy))]
pub struct Faq {
    #[cfg_attr(feature = "with-mocks", dummy(faker="Sentence(3..24)"))]
    title: String,
    #[cfg_attr(feature = "with-mocks", dummy(faker="Paragraph(3..12)"))]
    body: String,
}

impl Faq {

    pub fn title(&self) -> String {
        self.title.clone()
    }

    pub fn body(&self) -> String {
        self.body.clone()
    }
}


#[cfg(feature = "with-mocks")]
pub fn gen_mocks() -> Vec<Faq> {
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