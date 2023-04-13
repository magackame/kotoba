use crate::db::user::handle::Handle;
use crate::db::user::role::Role as UserRole;
use sqlx::mysql::{MySqlPool, MySqlQueryResult};
use sqlx::Result;
use uuid::Uuid;

pub struct User;

impl User {
    pub async fn exists_by_email(db_pool: &MySqlPool, email: &str) -> Result<bool> {
        sqlx::query!(
            "
            SELECT
                id
            FROM users
            WHERE email = ?
            ",
            email
        )
        .fetch_optional(db_pool)
        .await
        .map(|result| result.is_some())
    }

    pub async fn exists_by_handle(db_pool: &MySqlPool, handle: &str) -> Result<bool> {
        sqlx::query!(
            "
            SELECT
                id
            FROM users
            WHERE handle = ?
            ",
            handle
        )
        .fetch_optional(db_pool)
        .await
        .map(|result| result.is_some())
    }

    pub async fn insert(
        db_pool: &MySqlPool,
        handle: &Handle,
        email: &str,
        password: &str,
    ) -> Result<MySqlQueryResult> {
        let retoken = Uuid::new_v4().to_string();

        sqlx::query!(
            "
            INSERT INTO users
            (
                handle,
                profile_picture_file_id,
                role,
                full_name,
                description,
                is_bookmarks_private,
                is_following_private,
                email,
                password,
                retoken,
                joined_at
            )
            VALUES
            (
                ?,
                NULL,
                ?,
                '',
                '',
                TRUE,
                TRUE,
                ?,
                ?,
                ?,
                NOW()
            )
            ",
            handle.as_ref(),
            UserRole::Unverified.as_str(),
            email,
            password,
            retoken
        )
        .execute(db_pool)
        .await
    }
}
