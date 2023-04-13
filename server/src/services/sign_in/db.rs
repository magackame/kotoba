use crate::db::id::Id;
use crate::db::user::role::Role;
use sqlx::mysql::MySqlPool;
use sqlx::Result;

#[derive(Debug)]
pub struct User {
    pub id: Id,
    pub handle: String,
    pub profile_picture_file_name: Option<String>,
    pub role: Role,

    pub password: String,
}

impl User {
    pub async fn fetch_by_email(db_pool: &MySqlPool, email: &str) -> Result<Option<Self>> {
        sqlx::query_as!(
            Self,
            "
            SELECT
                users.id,
                handle,
                CONCAT(files.id, \".\", files.extension) AS profile_picture_file_name,
                role `role: Role`,
                password
            FROM users
                LEFT JOIN files ON users.profile_picture_file_id = files.id
            WHERE email = ?
            ",
            email
        )
        .fetch_optional(db_pool)
        .await
    }
}
