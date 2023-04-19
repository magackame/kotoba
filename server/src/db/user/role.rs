use serde::{Deserialize, Serialize};

pub const ROLE_ADMIN: &'static str = "Admin";
pub const ROLE_MOD: &'static str = "Mod";
pub const ROLE_MEMBER: &'static str = "Member";
pub const ROLE_BANNED: &'static str = "Banned";
pub const ROLE_UNVERIFIED: &'static str = "Unverified";

#[derive(Debug, Copy, Clone, Deserialize, Serialize, sqlx::Type)]
#[serde(tag = "tag")]
pub enum Role {
    Admin,
    Mod,
    Member,
    Banned,
    Unverified,
}

#[derive(Debug, Copy, Clone)]
pub enum Error {
    Invalid,
}

impl Role {
    pub fn from_str(role: &str) -> Result<Self, Error> {
        match role {
            ROLE_ADMIN => Ok(Self::Admin),
            ROLE_MOD => Ok(Self::Mod),
            ROLE_MEMBER => Ok(Self::Member),
            ROLE_BANNED => Ok(Self::Banned),
            ROLE_UNVERIFIED => Ok(Self::Unverified),
            _ => Err(Error::Invalid),
        }
    }

    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Admin => ROLE_ADMIN,
            Self::Mod => ROLE_MOD,
            Self::Member => ROLE_MEMBER,
            Self::Banned => ROLE_BANNED,
            Self::Unverified => ROLE_UNVERIFIED,
        }
    }

    pub fn can_post(&self) -> bool {
        match self {
            Self::Admin | Self::Mod | Self::Member => true,
            _ => false,
        }
    }

    pub fn can_edit_posts(&self) -> bool {
        match self {
            Self::Admin | Self::Mod | Self::Member => true,
            _ => false,
        }
    }

    pub fn can_translate_posts(&self) -> bool {
        match self {
            Self::Admin | Self::Mod | Self::Member => true,
            _ => false,
        }
    }

    pub fn can_manage_translations(&self) -> bool {
        match self {
            Self::Admin | Self::Mod | Self::Member => true,
            _ => false,
        }
    }

    pub fn can_comment(&self) -> bool {
        match self {
            Self::Admin | Self::Mod | Self::Member => true,
            _ => false,
        }
    }

    pub fn can_bookmark(&self) -> bool {
        match self {
            Self::Admin | Self::Mod | Self::Member => true,
            _ => false,
        }
    }

    pub fn can_follow(&self) -> bool {
        match self {
            Self::Admin | Self::Mod | Self::Member => true,
            _ => false,
        }
    }
}
