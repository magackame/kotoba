use crate::db::id::Id;
use crate::db::page::Page;
use serde::Serialize;
use sqlx::mysql::MySqlPool;
use sqlx::Result;

#[derive(Debug, Serialize)]
pub struct User {
    pub id: Id,
    pub handle: String,
    pub profile_picture_file_name: Option<String>,
    pub full_name: String,
    pub description: String,
}

impl User {
    pub async fn find(db_pool: &MySqlPool, query: &str, page: Page) -> Result<Vec<Self>> {
        let query = format!("%{}%", query);

        sqlx::query_as!(
            Self,
            "
            SELECT
                users.id,
                handle,
                CONCAT(files.id, \".\", files.extension) AS profile_picture_file_name,
                full_name,
                description
            FROM users
                LEFT JOIN files ON users.profile_picture_file_id = files.id
            WHERE handle LIKE ? OR full_name LIKE ? OR description LIKE ?
            LIMIT ? OFFSET ?
            ",
            &query,
            &query,
            &query,
            page.get_limit(),
            page.get_offset(),
        )
        .fetch_all(db_pool)
        .await
    }
}
