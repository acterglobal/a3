use super::{Color, Tag};

#[cfg(feature = "with-mocks")]
use fake::{
    Dummy,
    Fake,
    Faker,
    // faker::lorem::en::Paragraph,
};
#[cfg(feature = "with-mocks")]
use super::mocks::ColorFaker;

#[cfg(feature = "with-mocks")]
pub(crate) mod mocks {
    use fake::Dummy;
    use rand::Rng;
    use rand::prelude::*;

    pub struct RandomImage;

    impl Dummy<RandomImage> for Vec<u8> {
        fn dummy_with_rng<R: Rng + ?Sized>(_: &RandomImage, rng: &mut R) -> Self {
            vec![
                include_bytes!("./mocks/images/01.jpg").as_slice(),
                include_bytes!("./mocks/images/02.jpg").as_slice(),
                include_bytes!("./mocks/images/03.jpg").as_slice(),
                include_bytes!("./mocks/images/04.jpg").as_slice(),
                include_bytes!("./mocks/images/05.jpg").as_slice(),
                include_bytes!("./mocks/images/06.jpg").as_slice(),
                include_bytes!("./mocks/images/07.jpg").as_slice(),
            ].choose(rng).unwrap().to_vec()
        }
    }
}

#[cfg_attr(feature = "with-mocks", derive(Dummy))]
pub struct News {
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
    pub fn text(&self) -> &Option<String> {
        &self.text
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
