mod news;
mod faq;
mod tag;
mod color;

pub use news::{ News };
pub use faq::{ Faq };
pub use tag::{ Tag };
pub use color::{ Color };

#[cfg(feature = "with-mocks")]
pub mod mocks {
    pub use super::news::gen_mocks as gen_mock_news;
    pub use super::faq::gen_mocks as gen_mock_faqs;
    pub use super::color::mocks::ColorFaker;
}