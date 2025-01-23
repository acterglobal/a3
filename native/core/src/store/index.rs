use std::{fmt::Debug, ops::Deref};

use eyeball_im::{ObservableVector, ObservableVectorTransactionEntry, VectorDiff};
use futures::{Stream, StreamExt};
use matrix_sdk::ruma::{MilliSecondsSinceUnixEpoch, OwnedEventId};

use crate::{models::EventMeta, referencing::IndexKey};

/// Keeps an index of items sorted by the given rank, highest rank first
pub struct RankedIndex<K, T>
where
    K: 'static + Ord + Clone,
    T: 'static + Clone + Eq,
{
    vector: ObservableVector<(K, T)>,
}
impl<K, T> Default for RankedIndex<K, T>
where
    K: 'static + Ord + Clone,
    T: 'static + Clone + Eq,
{
    fn default() -> Self {
        Self {
            vector: Default::default(),
        }
    }
}

impl<K, T> Deref for RankedIndex<K, T>
where
    K: 'static + Ord + Clone,
    T: 'static + Clone + Eq,
{
    type Target = ObservableVector<(K, T)>;

    fn deref(&self) -> &Self::Target {
        &self.vector
    }
}

impl<K, T> RankedIndex<K, T>
where
    K: 'static + Ord + Clone,
    T: 'static + Clone + Eq,
{
    pub fn new_with(rank: K, value: T) -> Self {
        let mut m = RankedIndex::default();
        m.insert(rank, value);
        m
    }
    /// Insert the value T at the position of rank
    ///
    /// Will add at first position if a value of the same rank is found
    pub fn insert(&mut self, rank: K, value: T) {
        let mut pos = self.vector.len();
        for (idx, (k, _v)) in self.vector.iter().enumerate() {
            if k <= &rank {
                pos = idx;
                break;
            }
        }
        self.vector.insert(pos, (rank, value));
    }

    /// Remove all instances in the vector having the specific value
    pub fn remove(&mut self, value: &T) {
        let mut t = self.vector.transaction();
        let mut entries = t.entries();
        while let Some(entry) = entries.next() {
            if &entry.1 == value {
                ObservableVectorTransactionEntry::remove(entry);
            }
        }
        t.commit();
    }

    /// Returns the current list of values in order of their rank
    pub fn values(&self) -> Vec<&T> {
        self.vector.iter().map(|(_k, v)| v).collect()
    }

    pub fn update_stream(&self) -> impl Stream<Item = VectorDiff<T>> {
        self.vector.subscribe().into_stream().map(|v| match v {
            VectorDiff::Append { values } => VectorDiff::Append {
                values: values.into_iter().map(|(_k, v)| v).collect(),
            },
            VectorDiff::Clear => VectorDiff::Clear,
            VectorDiff::PushFront { value } => VectorDiff::PushFront { value: value.1 },
            VectorDiff::PushBack { value } => VectorDiff::PushBack { value: value.1 },
            VectorDiff::PopFront => VectorDiff::PopFront,
            VectorDiff::PopBack => VectorDiff::PopBack,
            VectorDiff::Insert { index, value } => VectorDiff::Insert {
                index,
                value: value.1,
            },
            VectorDiff::Set { index, value } => VectorDiff::Set {
                index,
                value: value.1,
            },
            VectorDiff::Remove { index } => VectorDiff::Remove { index },
            VectorDiff::Truncate { length } => VectorDiff::Truncate { length },
            VectorDiff::Reset { values } => VectorDiff::Reset {
                values: values.into_iter().map(|(_k, v)| v).collect(),
            },
        })
    }
}

/// Keeps an index of items sorted by when they were added
/// latest first
pub struct LifoIndex<T>
where
    T: 'static + Clone + Eq,
{
    vector: ObservableVector<T>,
}

impl<T> LifoIndex<T>
where
    T: 'static + Clone + Eq,
{
    pub fn new_with(value: T) -> Self {
        let mut m = LifoIndex::default();
        m.insert(value);
        m
    }
    /// Insert the element at the front
    pub fn insert(&mut self, value: T) {
        self.vector.push_front(value);
    }

    /// All instances of this element from the vector
    pub fn remove(&mut self, value: &T) {
        let mut t = self.vector.transaction();
        let mut entries = t.entries();
        while let Some(entry) = entries.next() {
            if &*entry == value {
                ObservableVectorTransactionEntry::remove(entry);
            }
        }
        t.commit();
    }

    /// Returns the current list of values in order of when they were added
    pub fn values(&self) -> Vec<&T> {
        self.vector.iter().collect()
    }

    pub fn update_stream(&self) -> impl Stream<Item = VectorDiff<T>> {
        self.vector.subscribe().into_stream()
    }
}

impl<T> Default for LifoIndex<T>
where
    T: 'static + Clone + Eq,
{
    fn default() -> Self {
        Self {
            vector: Default::default(),
        }
    }
}

impl<T> Deref for LifoIndex<T>
where
    T: 'static + Clone + Eq,
{
    type Target = ObservableVector<T>;

    fn deref(&self) -> &Self::Target {
        &self.vector
    }
}

pub enum StoreIndex {
    Lifo(LifoIndex<OwnedEventId>),
    Ranked(RankedIndex<MilliSecondsSinceUnixEpoch, OwnedEventId>),
}

impl StoreIndex {
    pub fn new_for(key: &IndexKey, meta: &EventMeta) -> StoreIndex {
        match key {
            IndexKey::ObjectHistory(_) | IndexKey::RoomHistory(_) => StoreIndex::Ranked(
                RankedIndex::new_with(meta.origin_server_ts, meta.event_id.clone()),
            ),
            _ => StoreIndex::Lifo(LifoIndex::new_with(meta.event_id.clone())),
        }
    }

    pub fn insert(&mut self, meta: &EventMeta) {
        match self {
            StoreIndex::Lifo(l) => l.insert(meta.event_id.clone()),
            StoreIndex::Ranked(r) => r.insert(meta.origin_server_ts, meta.event_id.clone()),
        }
    }

    /// All instances of this element from the vector
    pub fn remove(&mut self, value: &OwnedEventId) {
        match self {
            StoreIndex::Lifo(lifo_index) => lifo_index.remove(value),
            StoreIndex::Ranked(ranked_index) => ranked_index.remove(value),
        }
    }

    /// Returns the current list of values in order of when they were added
    pub fn values(&self) -> Vec<&OwnedEventId> {
        match self {
            StoreIndex::Lifo(lifo_index) => lifo_index.values(),
            StoreIndex::Ranked(ranked_index) => ranked_index.values(),
        }
    }

    // pub fn update_stream(&self) -> impl Stream<Item = VectorDiff<OwnedEventId>> {
    //     match self {
    //         StoreIndex::Lifo(lifo_index) => lifo_index.update_stream(),
    //         StoreIndex::Ranked(ranked_index) => ranked_index.update_stream(),
    //     }
    // }
}

impl Debug for StoreIndex {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Lifo(_) => f.debug_tuple("Lifo").finish(),
            Self::Ranked(_) => f.debug_tuple("Ranked").finish(),
        }
    }
}

#[cfg(test)]
mod tests {

    use super::*;
    use futures::pin_mut;
    use matrix_sdk_test::async_test;

    #[async_test]
    async fn test_ranked_index_for_u64() {
        let mut index = RankedIndex::<u64, &'static str>::default();
        index.insert(18, "18");
        index.insert(20, "20");
        index.insert(5, "5");
        index.insert(8, "8");

        assert_eq!(index.values(), [&"20", &"18", &"8", &"5",]);

        let stream = index.update_stream();

        index.remove(&"8");
        index.remove(&"18");

        assert_eq!(index.values(), [&"20", &"5"]);
        pin_mut!(stream);
        // ensure the right types and values
        assert!(matches!(
            stream.next().await.unwrap(),
            VectorDiff::Remove { index: 2 }
        ));
        assert!(matches!(
            stream.next().await.unwrap(),
            VectorDiff::Remove { index: 1 }
        ));
    }

    #[async_test]
    async fn test_lifo_index_for_u64() {
        let mut index = LifoIndex::<&'static str>::default();
        index.insert("18");
        index.insert("20");
        index.insert("5");
        index.insert("8");

        assert_eq!(index.values(), [&"8", &"5", &"20", &"18",]);

        let stream = index.update_stream();

        index.remove(&"18");
        index.remove(&"8");

        assert_eq!(index.values(), [&"5", &"20",]);
        pin_mut!(stream);
        // ensure the right types and values
        assert!(matches!(
            stream.next().await.unwrap(),
            VectorDiff::Remove { index: 3 }
        ));
        assert!(matches!(
            stream.next().await.unwrap(),
            VectorDiff::Remove { index: 0 }
        ));
    }
}
