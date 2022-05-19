pub use csscolorparser::Color;

#[cfg(feature = "with-mocks")]
pub(crate) mod mocks {
    use super::Color;
    use fake::Dummy;
    use rand::Rng;

    pub struct ColorFaker;

    impl Dummy<ColorFaker> for Color {
        fn dummy_with_rng<R: Rng + ?Sized>(_: &ColorFaker, _: &mut R) -> Self {
            Color::from_rgba_u8(12, 200, 120, 255)
        }
    }
}
