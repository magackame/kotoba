use crate::db::id::Id;
use sqlx::mysql::{MySqlPool, MySqlQueryResult};
use sqlx::Result;

pub async fn update_bookmark(
    db_pool: &MySqlPool,
    user_id: Id,
    post_id: Id,
) -> Result<MySqlQueryResult> {
    if bookmark_exists(db_pool, user_id, post_id).await? {
        delete_bookmark(db_pool, user_id, post_id).await
    } else {
        create_bookmark(db_pool, user_id, post_id).await
    }
}

async fn create_bookmark(
    db_pool: &MySqlPool,
    user_id: Id,
    post_id: Id,
) -> Result<MySqlQueryResult> {
    sqlx::query!(
        "
        INSERT INTO bookmarks
        (
            user_id,
            post_id
        )
        VALUES
        (
            ?,
            ?
        )
        ",
        user_id,
        post_id
    )
    .execute(db_pool)
    .await
}

async fn delete_bookmark(
    db_pool: &MySqlPool,
    user_id: Id,
    post_id: Id,
) -> Result<MySqlQueryResult> {
    sqlx::query!(
        "
        DELETE FROM bookmarks
        WHERE user_id = ? AND post_id = ?
        ",
        user_id,
        post_id
    )
    .execute(db_pool)
    .await
}

async fn bookmark_exists(db_pool: &MySqlPool, user_id: Id, post_id: Id) -> Result<bool> {
    sqlx::query!(
        "
        SELECT
            id
        FROM bookmarks
        WHERE user_id = ? AND post_id = ?
        ",
        user_id,
        post_id
    )
    .fetch_optional(db_pool)
    .await
    .map(|result| result.is_some())
}
