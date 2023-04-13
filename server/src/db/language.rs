use super::id::{Id, IdRow};
use serde::Serialize;
use sqlx::mysql::MySqlPool;
use sqlx::Result;

#[derive(Debug, Serialize)]
pub struct Language {
    pub id: Id,
    pub name: String,
}

pub async fn fetch_user_language_ids(db_pool: &MySqlPool, user_id: Id) -> Result<Vec<Id>> {
    sqlx::query_as!(
        IdRow,
        "
        SELECT
            id
        FROM user_languages
        WHERE user_id = ?
        ",
        user_id
    )
    .fetch_all(db_pool)
    .await
    .map(|id_rows| id_rows.into_iter().map(|id_row| id_row.id).collect())
}
