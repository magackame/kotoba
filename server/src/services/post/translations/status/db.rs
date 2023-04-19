use crate::db::id::Id;
use crate::db::post::status::Status as PostStatus;
use sqlx::mysql::{MySqlPool, MySqlQueryResult};
use sqlx::Result;

pub async fn is_posted_by(db_pool: &MySqlPool, post_content_id: Id, user_id: Id) -> Result<bool> {
    sqlx::query!(
        "
        SELECT
            posts.id
        FROM posts
            JOIN post_contents ON posts.id = post_contents.post_id
        WHERE
            post_contents.id = ?
            AND posted_by = ?
        ",
        post_content_id,
        user_id
    )
    .fetch_optional(db_pool)
    .await
    .map(|result| result.is_some())
}

pub async fn update_status(
    db_pool: &MySqlPool,
    post_content_id: Id,
    status: PostStatus,
) -> Result<()> {
    reset_status(db_pool, post_content_id).await?;
    set_status(db_pool, post_content_id, status).await?;

    Ok(())
}

async fn reset_status(db_pool: &MySqlPool, post_content_id: Id) -> Result<MySqlQueryResult> {
    sqlx::query!(
        "
        UPDATE post_contents
        SET
            status = ?
        WHERE
            id IN (
                SELECT
                    id
                FROM post_contents
                WHERE
                    post_id = (
                        SELECT
                            post_id
                        FROM post_contents
                        WHERE
                            id = ?
                    )
                    AND language_id = (
                        SELECT
                            language_id
                        FROM post_contents
                        WHERE
                            id = ?
                    )
            )
        ",
        PostStatus::Denied.as_str(),
        post_content_id,
        post_content_id
    )
    .execute(db_pool)
    .await
}
async fn set_status(
    db_pool: &MySqlPool,
    post_content_id: Id,
    status: PostStatus,
) -> Result<MySqlQueryResult> {
    sqlx::query!(
        "
        UPDATE post_contents
        SET
            status = ?
        WHERE
            id = ?
        ",
        status.as_str(),
        post_content_id,
    )
    .execute(db_pool)
    .await
}
