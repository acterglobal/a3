use matrix_sdk_ui::eyeball_im::VectorDiff;

pub struct ApiVectorDiff<T> {
    pub(crate) action: String,
    pub(crate) values: Option<Vec<T>>,
    pub(crate) index: Option<usize>,
    pub(crate) value: Option<T>,
}

impl<T> ApiVectorDiff<T>
where
    T: Clone,
{
    pub fn action(&self) -> String {
        self.action.clone()
    }

    pub fn values(&self) -> Option<Vec<T>> {
        match self.action.as_str() {
            "Append" | "Reset" => self.values.clone(),
            _ => None,
        }
    }

    pub fn index(&self) -> Option<usize> {
        match self.action.as_str() {
            "Insert" | "Set" | "Remove" => self.index,
            _ => None,
        }
    }

    pub fn value(&self) -> Option<T> {
        match self.action.as_str() {
            "Insert" | "Set" | "PushBack" | "PushFront" => self.value.clone(),
            _ => None,
        }
    }
}

impl<T> ApiVectorDiff<T> {
    pub fn current_items(values: Vec<T>) -> Self {
        ApiVectorDiff {
            action: "Reset".to_string(),
            values: Some(values),
            index: None,
            value: None,
        }
    }
}

pub fn remap_for_diff<E, T, C>(diff: VectorDiff<E>, mapper: C) -> ApiVectorDiff<T>
where
    C: Fn(E) -> T,
    T: Clone,
    E: Clone,
{
    match diff {
        // Append the given elements at the end of the `Vector` and notify subscribers
        VectorDiff::Append { values } => ApiVectorDiff {
            action: "Append".to_string(),
            values: Some(values.into_iter().map(mapper).collect()),
            index: None,
            value: None,
        },
        // Insert an element at the given position and notify subscribers
        VectorDiff::Insert { index, value } => ApiVectorDiff {
            action: "Insert".to_string(),
            values: None,
            index: Some(index),
            value: Some(mapper(value)),
        },
        // Replace the element at the given position, notify subscribers and return the previous element at that position
        VectorDiff::Set { index, value } => ApiVectorDiff {
            action: "Set".to_string(),
            values: None,
            index: Some(index),
            value: Some(mapper(value)),
        },
        // Remove the element at the given position, notify subscribers and return the element
        VectorDiff::Remove { index } => ApiVectorDiff {
            action: "Remove".to_string(),
            values: None,
            index: Some(index),
            value: None,
        },
        // Add an element at the back of the list and notify subscribers
        VectorDiff::PushBack { value } => ApiVectorDiff {
            action: "PushBack".to_string(),
            values: None,
            index: None,
            value: Some(mapper(value)),
        },
        // Add an element at the front of the list and notify subscribers
        VectorDiff::PushFront { value } => ApiVectorDiff {
            action: "PushFront".to_string(),
            values: None,
            index: None,
            value: Some(mapper(value)),
        },
        // Remove the last element, notify subscribers and return the element
        VectorDiff::PopBack => ApiVectorDiff {
            action: "PopBack".to_string(),
            values: None,
            index: None,
            value: None,
        },
        // Remove the first element, notify subscribers and return the element
        VectorDiff::PopFront => ApiVectorDiff {
            action: "PopFront".to_string(),
            values: None,
            index: None,
            value: None,
        },
        // Clear out all of the elements in this `Vector` and notify subscribers
        VectorDiff::Clear => ApiVectorDiff {
            action: "Clear".to_string(),
            values: None,
            index: None,
            value: None,
        },
        VectorDiff::Reset { values } => ApiVectorDiff {
            action: "Reset".to_string(),
            values: Some(values.into_iter().map(mapper).collect()),
            index: None,
            value: None,
        },
        // Truncate the vector to `len` elements and notify subscribers
        VectorDiff::Truncate { length } => ApiVectorDiff {
            action: "Truncate".to_string(),
            values: None,
            index: Some(length),
            value: None,
        },
    }
}

pub struct VecStringBuilder(pub(crate) Vec<String>);

impl Default for VecStringBuilder {
    fn default() -> Self {
        Self::new()
    }
}

impl VecStringBuilder {
    pub fn new() -> VecStringBuilder {
        VecStringBuilder(Vec::new())
    }
    pub fn add(&mut self, v: String) {
        self.0.push(v);
    }
}

pub fn new_vec_string_builder() -> VecStringBuilder {
    VecStringBuilder::new()
}
