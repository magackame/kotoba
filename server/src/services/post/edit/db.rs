use crate::db::id::Id;
use crate::db::post::content::Content;
use crate::db::post::description::Description;
use crate::db::post::insert_post_content_tags;
use crate::db::post::tags::Tags;
use crate::db::post::title::Title;
use sqlx::mysql::{MySqlPool, MySqlQueryResult};
use sqlx::Result;

pub async fn is_posted_by(db_pool: &MySqlPool, post_content_id: Id, user_id: Id) -> Result<bool> {
    sqlx::query!(
        "
        SELECT
            posts.id
        FROM posts
            JOIN post_contents ON posts.id = post_contents.post_id
        WHERE post_contents.id = ?
            AND posted_by = ?
        ",
        post_content_id,
        user_id
    )
    .fetch_optional(db_pool)
    .await
    .map(|result| result.is_some())
}

pub async fn update_post(
    db_pool: &MySqlPool,
    post_content_id: Id,
    language_id: Id,
    title: &Title,
    description: &Description,
    tags: &Tags,
    content: &Content,
) -> Result<()> {
    update_post_inner(
        db_pool,
        post_content_id,
        language_id,
        title,
        description,
        content,
    )
    .await?;

    delete_post_content_tags(db_pool, post_content_id).await?;
    insert_post_content_tags(db_pool, post_content_id, tags).await?;

    Ok(())
}

async fn delete_post_content_tags(
    db_pool: &MySqlPool,
    post_content_id: Id,
) -> Result<MySqlQueryResult> {
    sqlx::query!(
        "
        DELETE FROM post_content_tags
        WHERE post_content_id = ?
        ",
        post_content_id
    )
    .execute(db_pool)
    .await
}

async fn update_post_inner(
    db_pool: &MySqlPool,
    post_content_id: Id,
    language_id: Id,
    title: &Title,
    description: &Description,
    content: &Content,
) -> Result<MySqlQueryResult> {
    sqlx::query!(
        "
        UPDATE post_contents
        SET
            language_id = ?,
            title = ?,
            description = ?,
            content = ?
        WHERE id = ?
        ",
        language_id,
        title.as_ref(),
        description.as_ref(),
        content.as_ref(),
        post_content_id
    )
    .execute(db_pool)
    .await
}
