use derive_builder::Builder;
use ruma_events::{EventContent, PossiblyRedactedStateEventContent, StateEventType};
use ruma_macros::EventContent;
use serde::{
    de::{Deserializer, SeqAccess, Visitor},
    ser::{SerializeSeq, Serializer},
    Deserialize, Serialize,
};

use super::{Colorize, Icon};

/// The possibly redacted form of [`LabelsEventContent`].
///
/// This type is used when it's not obvious whether the content is redacted or not.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[allow(clippy::exhaustive_structs)]
pub struct PossiblyRedactedLabelsStateEventContent();

impl EventContent for PossiblyRedactedLabelsStateEventContent {
    type EventType = StateEventType;

    fn event_type(&self) -> Self::EventType {
        "global.acter.labels".into()
    }
}

impl PossiblyRedactedStateEventContent for PossiblyRedactedLabelsStateEventContent {
    type StateKey = String;
}

#[derive(Debug, Serialize, Deserialize, Clone, EventContent)]
#[ruma_event(type = "global.acter.labels", kind = State, state_key_type = String, custom_possibly_redacted)]
pub struct LabelsStateEventContent {
    #[serde(flatten)]
    pub labels: Vec<LabelDetails>,
}

#[derive(Debug, Serialize, Deserialize, Clone, Builder)]
pub struct LabelDetails {
    pub id: String,
    pub title: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub icon: Option<Icon>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub colorize: Option<Colorize>,
}

#[derive(Debug, PartialEq, Eq, Default, Clone)]
pub struct Labels {
    pub msgtype: Option<String>,
    pub category: Option<String>,
    pub tags: Vec<String>,
    pub sections: Vec<String>,
    pub others: Vec<String>,
}

impl Serialize for Labels {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let len = if self.msgtype.is_some() { 1 } else { 0 }
            + self.tags.len()
            + if self.category.is_some() { 1 } else { 0 }
            + self.others.len();
        let mut seq = serializer.serialize_seq(Some(len))?;
        if let Some(ref msg) = self.msgtype {
            seq.serialize_element(&format!("m.type:{msg:}"))?;
        }
        if let Some(ref cat) = self.category {
            seq.serialize_element(&format!("m.cat:{cat:}"))?;
        }
        for (prefix, entries) in [
            ("m.tag", self.tags.iter()),
            ("m.section", self.sections.iter()),
        ] {
            for e in entries {
                seq.serialize_element(&format!("{prefix:}:{e:}"))?;
            }
        }
        for e in self.others.iter() {
            seq.serialize_element(&e)?;
        }
        seq.end()
    }
}

pub struct LabelsVisitor;

impl<'de> Visitor<'de> for LabelsVisitor {
    type Value = Labels;

    fn expecting(&self, formatter: &mut std::fmt::Formatter) -> std::fmt::Result {
        formatter.write_str("List of Strings")
    }

    fn visit_seq<A>(self, mut seq: A) -> Result<Self::Value, A::Error>
    where
        A: SeqAccess<'de>,
    {
        let mut me = Labels::default();
        while let Some(key) = seq.next_element::<String>()? {
            if let Some((prefix, res)) = key.split_once(':') {
                match prefix {
                    // first has priority
                    "m.type" if me.msgtype.is_none() => me.msgtype = Some(res.to_string()),
                    "m.cat" if me.category.is_none() => me.category = Some(res.to_string()),
                    "m.tag" => me.tags.push(res.to_string()),
                    "m.section" => me.sections.push(res.to_string()),
                    _ => me.others.push(key),
                }
            } else {
                me.others.push(key)
            }
        }
        Ok(me)
    }
}

impl<'de> Deserialize<'de> for Labels {
    fn deserialize<D>(deserializer: D) -> Result<Labels, D::Error>
    where
        D: Deserializer<'de>,
    {
        deserializer.deserialize_seq(LabelsVisitor)
    }
}

#[cfg(test)]
mod test {
    use super::Labels;
    #[test]
    fn smoketest() -> Result<(), serde_json::Error> {
        let labels = Labels {
            msgtype: Some("m.message".to_string()),
            category: Some("animals".to_string()),
            tags: vec![
                "dog".to_string(),
                "animal".to_string(),
                "carnivor".to_string(),
            ],
            sections: vec!["work".to_string()],
            others: vec!["whatever".to_string(), "with:other:test".to_string()],
        };
        let ser = serde_json::to_string(&labels)?;
        println!("Serialized: {ser:}");

        let after: Labels = serde_json::from_str(&ser)?;
        assert_eq!(labels, after);
        Ok(())
    }

    #[test]
    fn first_type_has_priority() -> Result<(), serde_json::Error> {
        let labels = Labels {
            msgtype: Some("m.message".to_string()),
            category: Some("animals".to_string()),
            tags: vec![
                "dog".to_string(),
                "animal".to_string(),
                "carnivor".to_string(),
            ],
            sections: vec!["work".to_string()],
            others: vec![
                "m.type:whatever".to_string(), // relegated to "other"
                "m.cat:bad".to_string(),       // relegated to "other"
                "with:other:test".to_string(),
            ],
        };
        let ser = serde_json::to_string(&labels)?;
        println!("Serialized: {ser:}");

        let after: Labels = serde_json::from_str(&ser)?;
        assert_eq!(labels, after);
        Ok(())
    }
}
