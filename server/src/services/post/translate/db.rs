use crate::db::id::Id;
use sqlx::mysql::MySqlPool;
use sqlx::Result;

pub async fn is_posted_by(db_pool: &MySqlPool, post_id: Id, user_id: Id) -> Result<bool> {
    sqlx::query!(
        "
        SELECT
            id
        FROM posts
        WHERE
            id = ?
            AND posted_by = ?
        ",
        post_id,
        user_id
    )
    .fetch_optional(db_pool)
    .await
    .map(|result| result.is_some())
}
