use std::{fmt::Debug, ops::Deref};

use eyeball_im::{ObservableVector, ObservableVectorTransactionEntry, VectorDiff};
use futures::{Stream, StreamExt};

use crate::{
    meta::EventMeta,
    referencing::{IndexKey, ObjectListIndex, SectionIndex},
    traits::TypeConfig,
};

/// Keeps an index of items sorted by the given rank, highest rank first
pub struct RankedIndex<K, T>
where
    K: Ord + Clone + 'static,
    T: Clone + Eq + 'static,
{
    vector: ObservableVector<(K, T)>,
}
impl<K, T> Default for RankedIndex<K, T>
where
    K: Ord + Clone + 'static,
    T: Clone + Eq + 'static,
{
    fn default() -> Self {
        Self {
            vector: Default::default(),
        }
    }
}

impl<K, T> Deref for RankedIndex<K, T>
where
    K: Ord + Clone + 'static,
    T: Clone + Eq + 'static,
{
    type Target = ObservableVector<(K, T)>;

    fn deref(&self) -> &Self::Target {
        &self.vector
    }
}

impl<K, T> RankedIndex<K, T>
where
    K: Ord + Clone + 'static,
    T: Clone + Eq + 'static,
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

    pub fn update_stream(&self) -> impl Stream<Item = VectorDiff<T>> + use<K, T> {
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

struct GenericIndexVectorHandler();

impl GenericIndexVectorHandler {
    /// All instances of this element from the vector
    pub fn remove<T>(vector: &mut ObservableVector<T>, value: &T)
    where
        T: Clone + Eq + 'static,
    {
        let mut t = vector.transaction();
        let mut entries = t.entries();
        while let Some(entry) = entries.next() {
            if &*entry == value {
                ObservableVectorTransactionEntry::remove(entry);
            }
        }
        t.commit();
    }

    /// Returns the current list of values in order of when they were added
    pub fn values<T>(vector: &ObservableVector<T>) -> Vec<&T>
    where
        T: Clone + Eq + 'static,
    {
        vector.iter().collect()
    }

    pub fn update_stream<T>(
        vector: &ObservableVector<T>,
    ) -> impl Stream<Item = VectorDiff<T>> + use<T>
    where
        T: Clone + Eq + 'static,
    {
        vector.subscribe().into_stream()
    }
}

/// Keeps an index of items sorted by when they were added
/// latest first
pub struct LifoIndex<T>
where
    T: Clone + Eq + 'static,
{
    vector: ObservableVector<T>,
}

impl<T> LifoIndex<T>
where
    T: Clone + Eq + 'static,
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
        GenericIndexVectorHandler::remove(&mut self.vector, value)
    }

    /// Returns the current list of values in order of when they were added
    pub fn values(&self) -> Vec<&T> {
        GenericIndexVectorHandler::values(&self.vector)
    }

    pub fn update_stream(&self) -> impl Stream<Item = VectorDiff<T>> + use<T> {
        GenericIndexVectorHandler::update_stream(&self.vector)
    }
}

impl<T> Default for LifoIndex<T>
where
    T: Clone + Eq + 'static,
{
    fn default() -> Self {
        Self {
            vector: Default::default(),
        }
    }
}

impl<T> Deref for LifoIndex<T>
where
    T: Clone + Eq + 'static,
{
    type Target = ObservableVector<T>;

    fn deref(&self) -> &Self::Target {
        &self.vector
    }
}

/// Keeps an index of items sorted by when they were added
/// latest last
pub struct FiloIndex<T>
where
    T: Clone + Eq + 'static,
{
    vector: ObservableVector<T>,
}

impl<T> FiloIndex<T>
where
    T: Clone + Eq + 'static,
{
    pub fn new_with(value: T) -> Self {
        let mut m = FiloIndex::default();
        m.insert(value);
        m
    }
    /// Insert the element at the front
    pub fn insert(&mut self, value: T) {
        self.vector.push_back(value);
    }

    /// All instances of this element from the vector
    pub fn remove(&mut self, value: &T) {
        GenericIndexVectorHandler::remove(&mut self.vector, value)
    }

    /// Returns the current list of values in order of when they were added
    pub fn values(&self) -> Vec<&T> {
        GenericIndexVectorHandler::values(&self.vector)
    }

    pub fn update_stream(&self) -> impl Stream<Item = VectorDiff<T>> + use<T> {
        GenericIndexVectorHandler::update_stream(&self.vector)
    }
}

impl<T> Default for FiloIndex<T>
where
    T: Clone + Eq + 'static,
{
    fn default() -> Self {
        Self {
            vector: Default::default(),
        }
    }
}

impl<T> Deref for FiloIndex<T>
where
    T: Clone + Eq + 'static,
{
    type Target = ObservableVector<T>;

    fn deref(&self) -> &Self::Target {
        &self.vector
    }
}

pub enum StoreIndex<C: TypeConfig>
where
    C::ObjectId: 'static,
    C::Timestamp: 'static,
{
    Lifo(LifoIndex<C::ObjectId>),
    Filo(FiloIndex<C::ObjectId>),
    Ranked(RankedIndex<C::Timestamp, C::ObjectId>),
}

impl<C: TypeConfig> StoreIndex<C> {
    pub fn new_for(key: &IndexKey<C>, meta: &EventMeta<C>) -> StoreIndex<C> {
        match key {
            IndexKey::AllHistory | IndexKey::ObjectHistory(_) | IndexKey::RoomHistory(_) => {
                StoreIndex::Ranked(RankedIndex::new_with(
                    meta.timestamp.clone(),
                    meta.event_id.clone(),
                ))
            }
            //RSVPs are latest first for collection
            IndexKey::ObjectList(_, ObjectListIndex::Rsvp) => StoreIndex::Ranked(
                RankedIndex::new_with(meta.timestamp.clone(), meta.event_id.clone()),
            ),
            IndexKey::Section(SectionIndex::Boosts)
            | IndexKey::Section(SectionIndex::Stories)
            | IndexKey::RoomSection(_, SectionIndex::Boosts)
            | IndexKey::RoomSection(_, SectionIndex::Stories) => StoreIndex::Ranked(
                RankedIndex::new_with(meta.timestamp.clone(), meta.event_id.clone()),
            ),
            IndexKey::ObjectList(_, ObjectListIndex::Tasks) => {
                StoreIndex::Filo(FiloIndex::new_with(meta.event_id.clone()))
            }
            _ => StoreIndex::Lifo(LifoIndex::new_with(meta.event_id.clone())),
        }
    }

    pub fn insert(&mut self, meta: &EventMeta<C>) {
        match self {
            StoreIndex::Lifo(l) => l.insert(meta.event_id.clone()),
            StoreIndex::Filo(l) => l.insert(meta.event_id.clone()),
            StoreIndex::Ranked(r) => r.insert(meta.timestamp.clone(), meta.event_id.clone()),
        }
    }

    /// All instances of this element from the vector
    pub fn remove(&mut self, value: &C::ObjectId) {
        match self {
            StoreIndex::Lifo(idx) => idx.remove(value),
            StoreIndex::Filo(idx) => idx.remove(value),
            StoreIndex::Ranked(ranked_index) => ranked_index.remove(value),
        }
    }

    /// Returns the current list of values in order of when they were added
    pub fn values(&self) -> Vec<&C::ObjectId> {
        match self {
            StoreIndex::Lifo(idx) => idx.values(),
            StoreIndex::Filo(idx) => idx.values(),
            StoreIndex::Ranked(ranked_index) => ranked_index.values(),
        }
    }

    // pub fn update_stream(&self) -> impl Stream<Item = VectorDiff<OwnedEventId>> {
    //     match self {
    //         StoreIndex::Lifo(lifo_index) => lifo_index.update_stream(),
    //         StoreIndex::Filo(lifo_index) => lifo_index.update_stream(),
    //         StoreIndex::Ranked(ranked_index) => ranked_index.update_stream(),
    //     }
    // }
}

impl<C: TypeConfig> Debug for StoreIndex<C> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Lifo(_) => f.debug_tuple("Lifo").finish(),
            Self::Filo(_) => f.debug_tuple("Filo").finish(),
            Self::Ranked(_) => f.debug_tuple("Ranked").finish(),
        }
    }
}

#[cfg(test)]
mod tests {

    use crate::mocks::MockError;

    use super::*;
    use futures::pin_mut;

    #[tokio::test]
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

    #[tokio::test]
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

    #[test]
    fn test_ranked_index_deref() {
        let mut index = RankedIndex::<u64, &'static str>::default();
        index.insert(10, "10");
        index.insert(20, "20");

        // Test Deref implementation
        let vector_ref: &ObservableVector<(u64, &'static str)> = &index;
        assert_eq!(vector_ref.len(), 2);
        assert_eq!(vector_ref[0], (20, "20"));
        assert_eq!(vector_ref[1], (10, "10"));
    }

    #[test]
    fn test_lifo_index_deref() {
        let mut index = LifoIndex::<&'static str>::default();
        index.insert("first");
        index.insert("second");

        // Test Deref implementation
        let vector_ref: &ObservableVector<&'static str> = &index;
        assert_eq!(vector_ref.len(), 2);
        assert_eq!(vector_ref[0], "second");
        assert_eq!(vector_ref[1], "first");
    }

    #[test]
    fn test_filo_index_deref() {
        let mut index = FiloIndex::<&'static str>::default();
        index.insert("first");
        index.insert("second");

        // Test Deref implementation
        let vector_ref: &ObservableVector<&'static str> = &index;
        assert_eq!(vector_ref.len(), 2);
        assert_eq!(vector_ref[0], "first");
        assert_eq!(vector_ref[1], "second");
    }

    #[test]
    fn test_store_index_initialization() {
        use crate::meta::EventMeta;
        use crate::referencing::{IndexKey, ObjectListIndex, SectionIndex};
        use crate::traits::TypeConfig;
        use core::hash::Hash;

        // Mock TypeConfig for testing
        #[derive(Debug, Clone, PartialEq, Eq, Hash)]
        struct MockConfig;

        impl TypeConfig for MockConfig {
            type RoomId = String;
            type ObjectId = String;
            type ModelType = String;
            type AccountData = String;
            type UserId = String;
            type Timestamp = u64;
            type RedactionReason = String;
            type Error = MockError;
        }

        let meta = EventMeta::<MockConfig> {
            event_id: "test_event".to_string(),
            sender: "@user:example.com".to_string(),
            timestamp: 12345,
            room_id: "!room:example.com".to_string(),
            redacted: None,
        };

        // Test AllHistory
        let key = IndexKey::AllHistory;
        let index = StoreIndex::<MockConfig>::new_for(&key, &meta);
        assert!(matches!(index, StoreIndex::Ranked(_)));

        // Test ObjectHistory
        let key = IndexKey::ObjectHistory("obj1".to_string());
        let index = StoreIndex::<MockConfig>::new_for(&key, &meta);
        assert!(matches!(index, StoreIndex::Ranked(_)));

        // Test RoomHistory
        let key = IndexKey::RoomHistory("room1".to_string());
        let index = StoreIndex::<MockConfig>::new_for(&key, &meta);
        assert!(matches!(index, StoreIndex::Ranked(_)));

        // Test ObjectList with Rsvp
        let key = IndexKey::ObjectList("obj1".to_string(), ObjectListIndex::Rsvp);
        let index = StoreIndex::<MockConfig>::new_for(&key, &meta);
        assert!(matches!(index, StoreIndex::Ranked(_)));

        // Test ObjectList with Tasks
        let key = IndexKey::ObjectList("obj1".to_string(), ObjectListIndex::Tasks);
        let index = StoreIndex::<MockConfig>::new_for(&key, &meta);
        assert!(matches!(index, StoreIndex::Filo(_)));

        // Test Section Boosts
        let key = IndexKey::Section(SectionIndex::Boosts);
        let index = StoreIndex::<MockConfig>::new_for(&key, &meta);
        assert!(matches!(index, StoreIndex::Ranked(_)));

        // Test Section Stories
        let key = IndexKey::Section(SectionIndex::Stories);
        let index = StoreIndex::<MockConfig>::new_for(&key, &meta);
        assert!(matches!(index, StoreIndex::Ranked(_)));

        // Test RoomSection Boosts
        let key = IndexKey::RoomSection("room1".to_string(), SectionIndex::Boosts);
        let index = StoreIndex::<MockConfig>::new_for(&key, &meta);
        assert!(matches!(index, StoreIndex::Ranked(_)));

        // Test RoomSection Stories
        let key = IndexKey::RoomSection("room1".to_string(), SectionIndex::Stories);
        let index = StoreIndex::<MockConfig>::new_for(&key, &meta);
        assert!(matches!(index, StoreIndex::Ranked(_)));

        // Test default case (should be Lifo)
        let key = IndexKey::ObjectList("obj1".to_string(), ObjectListIndex::Comments);
        let index = StoreIndex::<MockConfig>::new_for(&key, &meta);
        assert!(matches!(index, StoreIndex::Lifo(_)));
    }

    #[test]
    fn test_store_index_operations() {
        use crate::meta::EventMeta;
        use crate::referencing::{IndexKey, ObjectListIndex};
        use crate::traits::TypeConfig;
        use core::hash::Hash;

        // Mock TypeConfig for testing
        #[derive(Debug, Clone, PartialEq, Eq, Hash)]
        struct MockConfig;

        impl TypeConfig for MockConfig {
            type RoomId = String;
            type ObjectId = String;
            type ModelType = String;
            type AccountData = String;
            type UserId = String;
            type Timestamp = u64;
            type RedactionReason = String;
            type Error = MockError;
        }

        let meta1 = EventMeta::<MockConfig> {
            event_id: "event1".to_string(),
            sender: "@user1:example.com".to_string(),
            timestamp: 100,
            room_id: "!room1:example.com".to_string(),
            redacted: None,
        };
        let meta2 = EventMeta::<MockConfig> {
            event_id: "event2".to_string(),
            sender: "@user2:example.com".to_string(),
            timestamp: 200,
            room_id: "!room2:example.com".to_string(),
            redacted: None,
        };

        // Test Lifo index operations
        let key = IndexKey::ObjectList("obj1".to_string(), ObjectListIndex::Comments);
        let mut index = StoreIndex::<MockConfig>::new_for(&key, &meta1);

        index.insert(&meta2);

        assert_eq!(index.values(), [&"event2", &"event1"]);

        index.remove(&"event1".to_string());
        assert_eq!(index.values(), [&"event2"]);

        // Test Filo index operations
        let key = IndexKey::ObjectList("obj1".to_string(), ObjectListIndex::Tasks);
        let mut index = StoreIndex::<MockConfig>::new_for(&key, &meta1);

        index.insert(&meta2);

        assert_eq!(index.values(), [&"event1", &"event2"]);

        index.remove(&"event1".to_string());
        assert_eq!(index.values(), [&"event2"]);

        // Test Ranked index operations
        let key = IndexKey::AllHistory;
        let mut index = StoreIndex::<MockConfig>::new_for(&key, &meta1);

        index.insert(&meta2);

        assert_eq!(index.values(), [&"event2", &"event1"]); // Higher timestamp first

        index.remove(&"event1".to_string());
        assert_eq!(index.values(), [&"event2"]);
    }

    #[test]
    fn test_store_index_debug() {
        use crate::meta::EventMeta;
        use crate::referencing::{IndexKey, ObjectListIndex};
        use crate::traits::TypeConfig;
        use core::hash::Hash;

        // Mock TypeConfig for testing
        #[derive(Debug, Clone, PartialEq, Eq, Hash)]
        struct MockConfig;

        impl TypeConfig for MockConfig {
            type RoomId = String;
            type ObjectId = String;
            type ModelType = String;
            type AccountData = String;
            type UserId = String;
            type Timestamp = u64;
            type RedactionReason = String;
            type Error = MockError;
        }

        let meta = EventMeta::<MockConfig> {
            event_id: "test_event".to_string(),
            sender: "@user:example.com".to_string(),
            timestamp: 12345,
            room_id: "!room:example.com".to_string(),
            redacted: None,
        };

        // Test Debug for Lifo
        let key = IndexKey::ObjectList("obj1".to_string(), ObjectListIndex::Comments);
        let index = StoreIndex::<MockConfig>::new_for(&key, &meta);
        assert_eq!(format!("{index:?}"), "Lifo");

        // Test Debug for Filo
        let key = IndexKey::ObjectList("obj1".to_string(), ObjectListIndex::Tasks);
        let index = StoreIndex::<MockConfig>::new_for(&key, &meta);
        assert_eq!(format!("{index:?}"), "Filo");

        // Test Debug for Ranked
        let key = IndexKey::AllHistory;
        let index = StoreIndex::<MockConfig>::new_for(&key, &meta);
        assert_eq!(format!("{index:?}"), "Ranked");
    }

    #[tokio::test]
    async fn test_ranked_index_update_stream_all_cases() {
        let mut index = RankedIndex::<u64, &'static str>::default();
        let stream = index.update_stream();
        pin_mut!(stream);

        // Test Append
        index.insert(10, "10");
        let next = stream.next().await.unwrap();
        assert!(matches!(
            next,
            VectorDiff::Insert { index: 0, value } if value == "10"
        ));

        // we do internal calls to make sure all these are going through properly
        index.vector.push_back((20, "20"));
        let next = stream.next().await.unwrap();
        assert!(matches!(
            next,
            VectorDiff::PushBack { value } if value == "20"
        ));

        index.vector.push_front((5, "5"));

        let next = stream.next().await.unwrap();
        assert!(matches!(
            next,
            VectorDiff::PushFront { value } if value == "5"
        ));

        index.vector.append([(25, "25"), (35, "35")].into());

        let next = stream.next().await.unwrap();
        assert!(matches!(
            next,
            VectorDiff::Append { ref values } if *values == vec!["25", "35"].into()
        ));

        // // Test Set
        // // Note: ObservableVector doesn't have a direct set method, so we'll test other cases

        // Test Remove
        index.remove(&"10");
        let next = stream.next().await.unwrap();
        assert!(matches!(next, VectorDiff::Remove { index: 1 }), "{next:?}");

        // Test Clear
        index.remove(&"5");
        index.remove(&"20");
        let next = stream.next().await.unwrap();
        assert!(matches!(next, VectorDiff::Remove { index: 0 }), "{next:?}");
        let next = stream.next().await.unwrap();
        assert!(matches!(next, VectorDiff::Remove { index: 0 }), "{next:?}");
    }

    #[tokio::test]
    async fn test_lifo_index_update_stream_all_cases() {
        let mut index = LifoIndex::<&'static str>::default();
        let stream = index.update_stream();
        pin_mut!(stream);

        // Test PushFront
        index.insert("first");
        index.insert("second");

        let next = stream.next().await.unwrap();
        assert!(matches!(
            next,
            VectorDiff::PushFront { value } if value == "first"
        ));
        let next = stream.next().await.unwrap();
        assert!(matches!(
            next,
            VectorDiff::PushFront { value } if value == "second"
        ));

        // Test Remove
        index.remove(&"first");
        let next = stream.next().await.unwrap();
        assert!(matches!(next, VectorDiff::Remove { index: 1 }), "{next:?}");

        // Test Clear
        index.remove(&"second");
        let next = stream.next().await.unwrap();
        assert!(matches!(next, VectorDiff::Remove { index: 0 }), "{next:?}");
    }

    #[tokio::test]
    async fn test_filo_index_update_stream_all_cases() {
        let mut index = FiloIndex::<&'static str>::default();
        let stream = index.update_stream();
        pin_mut!(stream);

        // Test PushBack
        index.insert("first");
        index.insert("second");
        let next = stream.next().await.unwrap();
        assert!(matches!(
            next,
            VectorDiff::PushBack { value } if value == "first"
        ));
        let next = stream.next().await.unwrap();
        assert!(matches!(
            next,
            VectorDiff::PushBack { value } if value == "second"
        ));

        // Test Remove
        index.remove(&"first");
        let next = stream.next().await.unwrap();
        assert!(matches!(next, VectorDiff::Remove { index: 0 }), "{next:?}");

        // Test Clear
        index.remove(&"second");
        let next = stream.next().await.unwrap();
        assert!(matches!(next, VectorDiff::Remove { index: 0 }), "{next:?}");
    }
}
