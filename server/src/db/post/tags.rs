use std::collections::HashSet;

#[derive(Debug, Copy, Clone)]
pub enum Error {
    NotEnough,
    TooMuch,
    Invalid,
    Duplicate,
}

#[derive(Debug)]
pub struct Tags(Vec<String>);

impl AsRef<Vec<String>> for Tags {
    fn as_ref(&self) -> &Vec<String> {
        &self.0
    }
}

impl Into<Vec<String>> for Tags {
    fn into(self) -> Vec<String> {
        self.0
    }
}

impl Tags {
    pub fn parse(tags: Vec<String>) -> Result<Self, Error> {
        if tags.len() < Self::min_amount() {
            return Err(Error::NotEnough);
        }

        if tags.len() > Self::max_amount() {
            return Err(Error::TooMuch);
        }

        if tags
            .iter()
            .map(|tag| Self::validate_tag(tag))
            .any(|is_valid| !is_valid)
        {
            return Err(Error::Invalid);
        }

        let mut tags_set = HashSet::new();
        if !tags.iter().all(|tag| tags_set.insert(tag)) {
            return Err(Error::Duplicate);
        }

        Ok(Self(tags))
    }

    pub fn min_amount() -> usize {
        2
    }

    pub fn max_amount() -> usize {
        7
    }

    pub fn max_char_count() -> usize {
        32
    }

    fn validate_tag(tag: &str) -> bool {
        if tag.is_empty() {
            return false;
        }

        if tag.chars().count() > Self::max_char_count() {
            return false;
        }

        true
    }
}
