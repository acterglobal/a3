use acter_core::events::{CategoriesStateEventContent, Category, CategoryBuilder};

pub struct Categories {
    inner: Option<CategoriesStateEventContent>,
}

pub struct CategoriesBuilder {
    entries: Vec<Category>,
}

impl Categories {
    pub fn new(inner: Option<CategoriesStateEventContent>) -> Self {
        Categories { inner }
    }
    pub fn categories(&self) -> Vec<Category> {
        self.inner
            .as_ref()
            .map(|i| i.categories.clone())
            .unwrap_or_default()
    }

    pub fn new_category_builder(&self) -> CategoryBuilder {
        CategoryBuilder::default().to_owned()
    }

    pub fn update_builder(&self) -> CategoriesBuilder {
        let entries = self.categories();
        CategoriesBuilder { entries }
    }
}

impl CategoriesBuilder {
    pub fn clear(&mut self) {
        self.entries.clear();
    }
    pub fn add(&mut self, cat: Box<Category>) {
        self.entries.push(*cat);
    }
    pub(crate) fn build(self) -> CategoriesStateEventContent {
        CategoriesStateEventContent {
            categories: self.entries,
        }
    }
}
