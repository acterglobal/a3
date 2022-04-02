mod news;

pub use news::{ News };

#[cfg(feature = "with-mocks")]
pub mod mocks {
    pub use super::news::gen_mocks as gen_mock_news;
}
