#[derive(Debug, Copy, Clone)]
pub enum Error {
    Empty,
    TooLong,
}

#[derive(Debug)]
pub struct Description(String);

impl AsRef<str> for Description {
    fn as_ref(&self) -> &str {
        &self.0
    }
}

impl Into<String> for Description {
    fn into(self) -> String {
        self.0
    }
}

impl Description {
    pub fn parse(description: String) -> Result<Self, Error> {
        Self::validate(&description)?;

        Ok(Self(description))
    }

    pub fn max_char_count() -> usize {
        8_192
    }

    fn validate(description: &str) -> Result<(), Error> {
        if description.is_empty() {
            return Err(Error::Empty);
        }

        if description.chars().count() > Self::max_char_count() {
            return Err(Error::TooLong);
        }

        Ok(())
    }
}
