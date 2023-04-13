use crate::db::language::Language;
use sqlx::mysql::MySqlPool;
use sqlx::Result;

pub const SUGGESTIONS_MAX_AMOUNT: u64 = 5;

pub async fn find(db_pool: &MySqlPool, query: &str) -> Result<Vec<Language>> {
    let query = format!("%{}%", query);

    sqlx::query_as!(
        Language,
        "
            SELECT
                id,
                name
            FROM languages
            WHERE name LIKE ?
            LIMIT ?
            ",
        query,
        SUGGESTIONS_MAX_AMOUNT
    )
    .fetch_all(db_pool)
    .await
}
