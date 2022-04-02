mod news;
mod faq;

pub use news::{ News };
pub use faq::{ Faq };

#[cfg(feature = "with-mocks")]
pub mod mocks {
    pub use super::news::gen_mocks as gen_mock_news;
    pub use super::faq::gen_mocks as gen_mock_faqs;
}
