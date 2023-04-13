use crate::db::id::Id;
use sqlx::mysql::MySqlPool;
use sqlx::Result;

#[derive(Debug)]
pub struct User {
    pub id: Id,
    pub handle: String,
    pub profile_picture_file_name: Option<String>,
    pub role: String,
}

impl User {
    pub async fn fetch_by_retoken(db_pool: &MySqlPool, retoken: &str) -> Result<Option<User>> {
        let result = sqlx::query_as!(
            User,
            "
        SELECT
            users.id,
            handle,
            CONCAT(files.id, \".\", files.extension) AS profile_picture_file_name,
            role
        FROM users
            LEFT JOIN files ON users.profile_picture_file_id = files.id
        WHERE retoken = ?
        ",
            retoken
        )
        .fetch_optional(db_pool)
        .await?;

        Ok(result)
    }
}
