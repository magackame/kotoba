#[derive(Debug, Copy, Clone)]
pub enum Error {
    Empty,
    TooLong,
}

#[derive(Debug)]
pub struct Title(String);

impl AsRef<str> for Title {
    fn as_ref(&self) -> &str {
        &self.0
    }
}

impl Into<String> for Title {
    fn into(self) -> String {
        self.0
    }
}

impl Title {
    pub fn parse(title: String) -> Result<Self, Error> {
        Self::validate(&title)?;

        Ok(Self(title))
    }

    pub fn max_char_count() -> usize {
        128
    }

    fn validate(title: &str) -> Result<(), Error> {
        if title.is_empty() {
            return Err(Error::Empty);
        }

        if title.chars().count() > Self::max_char_count() {
            return Err(Error::TooLong);
        }

        Ok(())
    }
}
