use crate::db::id::Id;
use crate::db::user::role::Role;
use chrono::NaiveDateTime;
use serde::Serialize;
use sqlx::mysql::MySqlPool;
use sqlx::Result;

#[derive(Debug, Serialize)]
pub struct User {
    pub id: Id,
    pub handle: String,
    pub profile_picture_file_name: Option<String>,
    pub role: Role,
    pub full_name: String,
    pub description: String,
    pub joined_at: i64,
    pub is_bookmarks_private: bool,
    pub is_following_private: bool,
    pub is_followed: bool,
}

impl User {
    pub async fn fetch_by_id(
        db_pool: &MySqlPool,
        fetcher_user_id: Option<Id>,
        id: Id,
    ) -> Result<Option<Self>> {
        let fetcher_user_id = fetcher_user_id.unwrap_or(0);

        let raw_user = match RawUser::fetch_by_id(db_pool, id).await? {
            Some(raw_user) => raw_user,
            None => return Ok(None),
        };

        let is_followed = is_followed(db_pool, fetcher_user_id, id).await?;

        // TODO: Better error handling
        let role = match Role::from_str(&raw_user.role) {
            Ok(role) => role,
            Err(_) => return Ok(None),
        };

        let user = Self {
            id: raw_user.id,
            handle: raw_user.handle,
            profile_picture_file_name: raw_user.profile_picture_file_name,
            role,
            full_name: raw_user.full_name,
            description: raw_user.description,
            joined_at: raw_user.joined_at.timestamp_millis(),
            is_bookmarks_private: raw_user.is_bookmarks_private != 0,
            is_following_private: raw_user.is_following_private != 0,
            is_followed,
        };

        Ok(Some(user))
    }
}

#[derive(Debug)]
struct RawUser {
    pub id: Id,
    pub handle: String,
    pub profile_picture_file_name: Option<String>,
    pub role: String,
    pub full_name: String,
    pub description: String,
    pub joined_at: NaiveDateTime,
    pub is_bookmarks_private: i8,
    pub is_following_private: i8,
}

impl RawUser {
    async fn fetch_by_id(db_pool: &MySqlPool, id: Id) -> Result<Option<Self>> {
        sqlx::query_as!(
            Self,
            "
            SELECT
                users.id,
                handle,
                CONCAT(files.id, \".\", files.extension) as profile_picture_file_name,
                role,
                full_name,
                description,
                is_bookmarks_private,
                is_following_private,
                joined_at
            FROM users
                LEFT JOIN files ON users.profile_picture_file_id = files.id
            WHERE users.id = ?
            ",
            id,
        )
        .fetch_optional(db_pool)
        .await
    }
}

pub async fn is_followed(
    db_pool: &MySqlPool,
    follower_user_id: Id,
    followed_user_id: Id,
) -> Result<bool> {
    sqlx::query!(
        "
        SELECT
            id
        FROM followers
        WHERE follower_user_id = ? and followed_user_id = ?
        ",
        follower_user_id,
        followed_user_id
    )
    .fetch_optional(db_pool)
    .await
    .map(|row| row.is_some())
}
