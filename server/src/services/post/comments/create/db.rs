use crate::db::comment::content::Content;
use crate::db::id::Id;
use sqlx::mysql::{MySqlPool, MySqlQueryResult};
use sqlx::Result;

pub async fn insert_comment(
    db_pool: &MySqlPool,
    post_content_id: Id,
    reply_to: Option<Id>,
    content: &Content,
    posted_by: Id,
) -> Result<MySqlQueryResult> {
    sqlx::query!(
        "
        INSERT INTO comments
        (
            post_content_id,
            reply_to,
            content,
            posted_by,
            posted_at
        )
        VALUES
        (
            ?,
            ?,
            ?,
            ?,
            NOW()
        )
        ",
        post_content_id,
        reply_to,
        content.as_ref(),
        posted_by
    )
    .execute(db_pool)
    .await
}
