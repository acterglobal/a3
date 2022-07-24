#[derive(Clone, Debug)]
pub struct DeviceChangesEvent {
    changed: Vec<String>,
    left: Vec<String>,
}

impl DeviceChangesEvent {
    pub(crate) fn new(changed: Vec<String>, left: Vec<String>) -> Self {
        Self {
            changed,
            left,
        }
    }

    pub fn get_changed(&self) -> Vec<String> {
        self.changed.clone()
    }

    pub fn get_left(&self) -> Vec<String> {
        self.left.clone()
    }
}
