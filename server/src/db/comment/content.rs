#[derive(Debug, Copy, Clone)]
pub enum Error {
    Empty,
    TooLong,
}

#[derive(Debug)]
pub struct Content(String);

impl AsRef<str> for Content {
    fn as_ref(&self) -> &str {
        &self.0
    }
}

impl Into<String> for Content {
    fn into(self) -> String {
        self.0
    }
}

impl Content {
    pub fn parse(content: String) -> Result<Self, Error> {
        Self::validate(&content)?;

        Ok(Self(content))
    }

    pub fn max_char_count() -> usize {
        4_096
    }

    fn validate(content: &str) -> Result<(), Error> {
        if content.is_empty() {
            return Err(Error::Empty);
        }

        if content.chars().count() > Self::max_char_count() {
            return Err(Error::TooLong);
        }

        Ok(())
    }
}
