use super::{Color, Tag};
use matrix_sdk::ruma::OwnedEventId;

#[cfg(feature = "with-mocks")]
use super::mocks::ColorFaker;
#[cfg(feature = "with-mocks")]
use fake::{
    faker::lorem::en::{Sentence, Word},
    Dummy, Fake, Faker,
};

#[cfg(feature = "with-mocks")]
pub(crate) mod mocks {
    use fake::Dummy;
    use rand::prelude::*;
    use rand::Rng;

    pub struct RandomImage;
    pub static IMAGE_001: &[u8] = include_bytes!("./mocks/images/07.jpg").as_slice();
    pub static IMAGE_002: &[u8] = include_bytes!("./mocks/images/02.jpg").as_slice();
    pub static IMAGE_003: &[u8] = include_bytes!("./mocks/images/03.jpg").as_slice();
    pub static IMAGE_004: &[u8] = include_bytes!("./mocks/images/04.jpg").as_slice();
    pub static IMAGE_005: &[u8] = include_bytes!("./mocks/images/05.jpg").as_slice();
    pub static IMAGE_006: &[u8] = include_bytes!("./mocks/images/06.jpg").as_slice();
    pub static IMAGE_007: &[u8] = include_bytes!("./mocks/images/07.jpg").as_slice();

    impl Dummy<RandomImage> for Vec<u8> {
        fn dummy_with_rng<R: Rng + ?Sized>(_: &RandomImage, rng: &mut R) -> Self {
            vec![
                IMAGE_001, IMAGE_002, IMAGE_003, IMAGE_004, IMAGE_005, IMAGE_006, IMAGE_007,
            ]
            .choose(rng)
            .unwrap()
            .to_vec()
        }
    }
}

#[cfg_attr(feature = "with-mocks", derive(Dummy))]
#[derive(Default)]
pub struct News {
    #[cfg_attr(feature = "with-mocks", dummy(faker = "Word()"))]
    id: String,
    #[cfg_attr(feature = "with-mocks", dummy(faker = "Sentence(3..24)"))]
    text: Option<String>,
    pub(crate) tags: Vec<Tag>,
    #[cfg_attr(feature = "with-mocks", dummy(faker = "0..1024"))]
    pub(crate) likes_count: u64,
    #[cfg_attr(feature = "with-mocks", dummy(faker = "0..324"))]
    pub(crate) comments_count: u64,
    #[cfg_attr(feature = "with-mocks", dummy(faker = "ColorFaker"))]
    pub(crate) bg_color: Option<Color>,
    #[cfg_attr(feature = "with-mocks", dummy(faker = "ColorFaker"))]
    pub(crate) fg_color: Option<Color>,
    #[cfg_attr(feature = "with-mocks", dummy(faker = "mocks::RandomImage"))]
    pub(crate) image: Option<Vec<u8>>,
}

impl News {
    pub fn event_id(&self) -> OwnedEventId {
        OwnedEventId::try_from("$DCtqUwJhmslGOcylXIxLuvcaBV2GLwZPAUCA1HlVKQw")
            .expect("static owned id works")
    }
    pub fn id(&self) -> String {
        self.id.clone()
    }
    pub fn text(&self) -> Option<String> {
        self.text.clone()
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
    pub fn bg_color(&self) -> Option<Color> {
        self.bg_color.clone()
    }
    pub fn fg_color(&self) -> Option<Color> {
        self.fg_color.clone()
    }
    pub fn image(&self) -> Option<Vec<u8>> {
        self.image.clone()
    }
}

#[cfg(feature = "with-mocks")]
pub fn gen_mocks() -> Vec<News> {
    pub static JACKS_BIRTHDAY: &[u8] =
        include_bytes!("./mocks/images/jacksbirthday.png").as_slice();
    pub static SPORTING_INVITE: &[u8] =
        include_bytes!("./mocks/images/sporting-invite.png").as_slice();
    pub static PARTY: &[u8] = include_bytes!("./mocks/images/party.png").as_slice();
    pub static PARTY_RECAP: &[u8] = include_bytes!("./mocks/images/party-recap.jpg").as_slice();
    pub static TRIP: &[u8] = include_bytes!("./mocks/images/charlies-trip.png").as_slice();
    vec![
        News {
            id: "uncle-jacks".to_string(),
            text: Some("Jacks birthday is coming up".to_string()),
            likes_count: 25,
            comments_count: 11,
            image: Some(JACKS_BIRTHDAY.to_vec()),
            fg_color: Some(Color::from_rgb_u8(255, 255, 255)),
            bg_color: Some(Color::from_rgb_u8(0, 0, 0)),
            ..Default::default()
        },
        News {
            id: "sports".to_string(),
            text: Some("You coming to our sports event?".to_string()),
            likes_count: 89,
            comments_count: 18,
            image: Some(SPORTING_INVITE.to_vec()),
            fg_color: Some(Color::from_rgb_u8(255, 255, 255)),
            bg_color: Some(Color::from_rgb_u8(0, 0, 0)),
            ..Default::default()
        },
        News {
            id: "family-party-recap".to_string(),
            text: Some("Family party recap.".to_string()),
            likes_count: 7,
            comments_count: 3,
            image: Some(PARTY_RECAP.to_vec()),
            fg_color: Some(Color::from_rgb_u8(255, 255, 255)),
            bg_color: Some(Color::from_rgb_u8(0, 0, 0)),
            ..Default::default()
        },
        News {
            id: "ref-camps".to_string(),
            text: Some("Our transport is on its way to Poland, to refugee camps".to_string()),
            likes_count: 23,
            comments_count: 2,
            image: Some(mocks::IMAGE_001.to_vec()),
            fg_color: Some(Color::from_rgb_u8(255, 255, 255)),
            bg_color: Some(Color::from_rgb_u8(0, 0, 0)),
            ..Default::default()
        },
        News {
            id: "charlies-trip".to_string(),
            text: Some("My Trip was great.".to_string()),
            likes_count: 9,
            comments_count: 8,
            image: Some(TRIP.to_vec()),
            fg_color: Some(Color::from_rgb_u8(255, 255, 255)),
            bg_color: Some(Color::from_rgb_u8(0, 0, 0)),
            ..Default::default()
        },
        News {
            id: "what-s-needed".to_string(),
            text: Some("What is currently needed to help Ukrainian refugees ".to_string()),
            likes_count: 102,
            comments_count: 14,
            image: Some(mocks::IMAGE_002.to_vec()),
            fg_color: Some(Color::from_rgb_u8(255, 255, 255)),
            bg_color: Some(Color::from_rgb_u8(0, 0, 0)),
            ..Default::default()
        },
        News {
            id: "party-simple".to_string(),
            text: Some("Party was a blast. Thanks guys!".to_string()),
            likes_count: 6,
            comments_count: 1,
            image: Some(PARTY.to_vec()),
            fg_color: Some(Color::from_rgb_u8(255, 255, 255)),
            bg_color: Some(Color::from_rgb_u8(0, 0, 0)),
            ..Default::default()
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
