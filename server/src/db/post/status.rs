pub const STATUS_PENDING: &'static str = "Pending";
pub const STATUS_APPROVED: &'static str = "Approved";
pub const STATUS_DENIED: &'static str = "Denied";

#[derive(Debug, sqlx::Type)]
pub enum Status {
    Pending,
    Approved,
    Denied,
}

#[derive(Debug, Copy, Clone)]
pub enum Error {
    Invalid,
}

impl Status {
    pub fn from_str(status: &str) -> Result<Self, Error> {
        match status {
            STATUS_PENDING => Ok(Self::Pending),
            STATUS_APPROVED => Ok(Self::Approved),
            STATUS_DENIED => Ok(Self::Denied),
            _ => Err(Error::Invalid),
        }
    }

    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Pending => STATUS_PENDING,
            Self::Approved => STATUS_APPROVED,
            Self::Denied => STATUS_DENIED,
        }
    }
}
