#[cfg(feature = "with-mocks")]
use crate::models::color::mocks::ColorFaker;
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
    let phone_numbers = Tag {
        title: "phone-numbers".to_string(),
        color: None,
    };
    let important = Tag {
        title: "important".to_string(),
        color: ColorFaker.fake(),
    };
    vec![
        Faq {
            title: "All Important Info about Uncle Jack's 65th Birthday".to_string(),
            body: "We'll meet at João's Place, 7871 Faria Via, Braga - you need to follow the long road to the end, through the gate and the fields. Number for the gate lock is 124436 . For important last minute info, call +351 916185416".to_string(),
            pinned: true,
            tags: vec![important.clone(), Tag { title: "birthday".to_string(), color: ColorFaker.fake() }, Tag { title: "party".to_string(), color: ColorFaker.fake() }],
            likes_count: 64,
            comments_count: 8,
        },
        Faq {
            title: "Esporting Schedule".to_string(),
            body: "This week, we will meet Wednesday, Friday and Sunday at 3pm and Monday and Tuesday at 6pm for soccess practice at the stadium. There will also be a jogging round every morning 6am and 9am for those interested, starting punctual from the club house. Newcomers welcome".to_string(),
            pinned: true,
            tags: vec![important, Tag { title: "schedule".to_string(), color:  ColorFaker.fake() }],
            likes_count: 12,
            comments_count: 3,
        },
        Faq {
            title: "Fridge Phone Numbers".to_string(),
            body: "Most important Phone numbers:<br> - Kims Doctor: +351 916758991 <br> - Garage: +351 357768873<br> - Dentist: +351 206506277<br> - Vet: +351 938979689".to_string(),
            pinned: true,
            tags: vec![phone_numbers.clone()],
            likes_count: 4,
            comments_count: 2,
        },
        Faq {
            title: "Car Insurance and accident info".to_string(),
            body: "Insurance: Allianz Santo Antonio, Parque Moserrate, Sintra<br>Phone number: 21 923 7300".to_string(),
            pinned: false,
            tags: vec![phone_numbers.clone()],
            likes_count: 312,
            comments_count: 8,
        },
        Faq {
            title: "How to become a coach/trainer for OpenTechSchool?".to_string(),
            body: "Coaches help to spread the fun of coding. They are not only supporting learners with the expertise and knowledge, they also try to create a friendly and welcoming environment at the events. Learn more about <a href=\"https://www.opentechschool.org/guides#coaching-guidelines\">our coaching guidelines here</a>".to_string(),
            pinned: false,
            tags: vec![Tag { title: "coaching".to_string(), color: None }],
            likes_count: 312,
            comments_count: 8,
        },
        Faker.fake(),
        Faker.fake(),
    ]
}
