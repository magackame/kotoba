use crate::db::comment::content::Error as CommentContentError;
use crate::db::post::{
    content::Error as PostContentError, description::Error as DescriptionError,
    tags::Error as TagsError, title::Error as TitleError,
};
use crate::db::user::handle::Error as HandleError;
use crate::db::user::role::Error as UserRoleError;
use actix_web::ResponseError;

// I know that this is an anti-pattern, but
// If any of this errors occurs the server
// either can't do anything meaningfull
// or the error should have been cought
// at the front-end validation phase
#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error("sqlx error")]
    Sqlx(#[from] sqlx::Error),
    #[error("Argon2 error")]
    Argon2,
    #[error("JWT error")]
    Jwt(#[from] jwt_simple::Error),
    #[error("Validation error")]
    Validation,
    #[error("Invalid user role fetched from db")]
    InvalidUserRole,
}

impl From<argon2::password_hash::Error> for Error {
    fn from(_: argon2::password_hash::Error) -> Self {
        Self::Argon2
    }
}

impl From<HandleError> for Error {
    fn from(_: HandleError) -> Self {
        Self::Validation
    }
}

impl From<CommentContentError> for Error {
    fn from(_: CommentContentError) -> Self {
        Self::Validation
    }
}

impl From<TitleError> for Error {
    fn from(_: TitleError) -> Self {
        Self::Validation
    }
}

impl From<TagsError> for Error {
    fn from(_: TagsError) -> Self {
        Self::Validation
    }
}

impl From<PostContentError> for Error {
    fn from(_: PostContentError) -> Self {
        Self::Validation
    }
}

impl From<DescriptionError> for Error {
    fn from(_: DescriptionError) -> Self {
        Self::Validation
    }
}

impl From<UserRoleError> for Error {
    fn from(_: UserRoleError) -> Self {
        Self::InvalidUserRole
    }
}

impl ResponseError for Error {
    // TODO: Unauthorized status code for Unauthorized
}
