use crate::models::Tag;

#[cfg(feature = "with-mocks")]
use fake::{
    faker::lorem::en::{Paragraph, Sentence},
    Dummy, Fake, Faker,
};

#[cfg_attr(feature = "with-mocks", derive(Dummy))]
#[derive(Clone)]
pub struct Faq {
    #[cfg_attr(feature = "with-mocks", dummy(faker = "Sentence(3..24)"))]
    pub(crate) title: String,
    #[cfg_attr(feature = "with-mocks", dummy(faker = "Paragraph(3..12)"))]
    pub(crate) body: String,
    pub(crate) pinned: bool,
    pub(crate) tags: Vec<Tag>,
    #[cfg_attr(feature = "with-mocks", dummy(faker = "0..1024"))]
    pub(crate) likes_count: u64,
    #[cfg_attr(feature = "with-mocks", dummy(faker = "0..324"))]
    pub(crate) comments_count: u64,
}

impl Faq {
    pub fn title(&self) -> String {
        self.title.clone()
    }

    pub fn body(&self) -> String {
        self.body.clone()
    }

    pub fn pinned(&self) -> bool {
        self.pinned
    }

    pub fn tags(&self) -> Vec<Tag> {
        self.tags.clone()
    }

    pub fn likes_count(&self) -> u64 {
        self.likes_count
    }

    pub fn comments_count(&self) -> u64 {
        self.comments_count
    }
}

#[cfg(feature = "with-mocks")]
pub fn gen_mocks() -> Vec<Faq> {
    vec![
        Faq {
            title: "How to become a coach/trainer for OpenTechSchool?".to_string(),
            body: "Coaches help to spread the fun of coding. They are not only supporting learners with the expertise and knowledge, they also try to create a friendly and welcoming environment at the events. Learn more about <a href=\"https://www.opentechschool.org/guides#coaching-guidelines\">our coaching guidelines here</a>".to_string(),
            pinned: true,
            tags: vec![Tag { title: "coaching".to_string(), color: None }],
            likes_count: 123,
            comments_count: 14,
        },
        Faq {
            title: "How to become a coach/trainer for OpenTechSchool?".to_string(),
            body: "Coaches help to spread the fun of coding. They are not only supporting learners with the expertise and knowledge, they also try to create a friendly and welcoming environment at the events. Learn more about <a href=\"https://www.opentechschool.org/guides#coaching-guidelines\">our coaching guidelines here</a>".to_string(),
            pinned: true,
            tags: vec![Tag { title: "coaching".to_string(), color: None }],
            likes_count: 312,
            comments_count: 8,
        },
        Faker.fake(),
        Faker.fake(),
        Faker.fake(),
        Faker.fake(),
        Faker.fake(),
        Faker.fake(),
        Faker.fake(),
    ]
}
