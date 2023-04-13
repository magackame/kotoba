use super::id::Id;
use super::user::meta::Meta as UserMeta;
use chrono::NaiveDateTime;
use serde::Serialize;

pub mod content;

pub mod reply;
use reply::Reply;

#[derive(Debug, Serialize)]
pub struct Comment {
    pub id: Id,
    pub post_content_id: Id,
    pub reply_to: Option<Reply>,
    pub content: String,
    pub posted_by: UserMeta,
    pub posted_at: i64,
}

impl From<RawComment> for Comment {
    fn from(raw: RawComment) -> Self {
        Self {
            id: raw.id,
            post_content_id: raw.post_content_id,
            reply_to: raw.reply_to_id.map(|comment_id| Reply {
                comment_id,
                reply_to: UserMeta {
                    // SAFETY: This field is tied to `reply_to_id` in DB,
                    // so it should also be `Some` if `reply_to_id` is `Some`
                    id: raw.reply_to_user_id.unwrap(),
                    // SAFETY: This field is tied to `reply_to_id` in DB,
                    // so it should also be `Some` if `reply_to_id` is `Some`
                    handle: raw.reply_to_handle.unwrap(),
                    // SAFETY: This field is tied to `reply_to_id` in DB,
                    // so it should also be `Some` if `reply_to_id` is `Some`
                    profile_picture_file_name: raw.reply_to_profile_picture_file_name,
                },
            }),
            content: raw.content,
            posted_by: UserMeta {
                id: raw.posted_by_id,
                handle: raw.posted_by_handle,
                profile_picture_file_name: raw.posted_by_profile_picture_file_name,
            },
            posted_at: raw.posted_at.timestamp_millis(),
        }
    }
}

#[derive(Debug, sqlx::FromRow)]
pub struct RawComment {
    pub id: Id,
    pub post_content_id: Id,
    pub reply_to_id: Option<Id>,
    pub reply_to_user_id: Option<Id>,
    pub reply_to_handle: Option<String>,
    pub reply_to_profile_picture_file_name: Option<String>,
    pub content: String,
    pub posted_by_id: Id,
    pub posted_by_handle: String,
    pub posted_by_profile_picture_file_name: Option<String>,
    pub posted_at: NaiveDateTime,
}
