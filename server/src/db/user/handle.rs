use regex::Regex;

#[derive(Debug, Copy, Clone)]
pub enum Error {
    Empty,
    TooLong,
    BadChar,
}

#[derive(Debug)]
pub struct Handle(String);

impl AsRef<str> for Handle {
    fn as_ref(&self) -> &str {
        &self.0
    }
}

impl Into<String> for Handle {
    fn into(self) -> String {
        self.0
    }
}

impl Handle {
    pub fn parse<'a>(handle: String) -> Result<Self, Error> {
        Self::validate(&handle)?;

        Ok(Self(handle))
    }

    pub fn max_char_count() -> usize {
        64
    }

    fn validate(s: &str) -> Result<(), Error> {
        if s.is_empty() {
            return Err(Error::Empty);
        }

        if s.chars().count() > Self::max_char_count() {
            return Err(Error::TooLong);
        }

        // TODO: lazy_static!
        let regex = Regex::new("^[\\-_A-Za-z0-9]+$").expect("Failed to compile handle regex");

        if !regex.is_match(s) {
            return Err(Error::BadChar);
        }

        Ok(())
    }
}
