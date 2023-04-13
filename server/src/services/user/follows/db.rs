use crate::db::id::Id;
use sqlx::mysql::{MySqlPool, MySqlQueryResult};
use sqlx::Result;

pub async fn update_follow(
    db_pool: &MySqlPool,
    follower_user_id: Id,
    followed_user_id: Id,
) -> Result<MySqlQueryResult> {
    if follow_exists(db_pool, follower_user_id, followed_user_id).await? {
        delete_follow(db_pool, follower_user_id, followed_user_id).await
    } else {
        create_follow(db_pool, follower_user_id, followed_user_id).await
    }
}

async fn create_follow(
    db_pool: &MySqlPool,
    follower_user_id: Id,
    followed_user_id: Id,
) -> Result<MySqlQueryResult> {
    sqlx::query!(
        "
        INSERT INTO followers
        (
            follower_user_id,
            followed_user_id
        )
        VALUES
        (
            ?,
            ?
        )
        ",
        follower_user_id,
        followed_user_id
    )
    .execute(db_pool)
    .await
}

async fn delete_follow(
    db_pool: &MySqlPool,
    follower_user_id: Id,
    followed_user_id: Id,
) -> Result<MySqlQueryResult> {
    sqlx::query!(
        "
        DELETE FROM followers
        WHERE follower_user_id = ? AND followed_user_id = ?
        ",
        follower_user_id,
        followed_user_id
    )
    .execute(db_pool)
    .await
}

async fn follow_exists(
    db_pool: &MySqlPool,
    follower_user_id: Id,
    followed_user_id: Id,
) -> Result<bool> {
    sqlx::query!(
        "
        SELECT
            id
        FROM followers
        WHERE follower_user_id = ? AND followed_user_id = ?
        ",
        follower_user_id,
        followed_user_id
    )
    .fetch_optional(db_pool)
    .await
    .map(|result| result.is_some())
}
