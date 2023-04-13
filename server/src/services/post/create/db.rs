use crate::db::id::Id;
use crate::db::post::content::Content;
use crate::db::post::description::Description;
use crate::db::post::insert_post_content;
use crate::db::post::insert_post_content_tags;
use crate::db::post::status::Status;
use crate::db::post::tags::Tags;
use crate::db::post::title::Title;
use sqlx::mysql::{MySqlPool, MySqlQueryResult};
use sqlx::Result;

pub async fn insert_post(
    db_pool: &MySqlPool,
    posted_by_user_id: Id,
    language_id: Id,
    title: &Title,
    description: &Description,
    tags: &Tags,
    content: &Content,
) -> Result<Id> {
    let posts_insert_result = insert_post_inner(db_pool, posted_by_user_id).await?;

    let post_id = posts_insert_result.last_insert_id() as Id;
    let post_contents_insert_result = insert_post_content(
        db_pool,
        post_id,
        language_id,
        title,
        description,
        content,
        Status::Approved,
        posted_by_user_id,
    )
    .await?;

    let post_content_id = post_contents_insert_result.last_insert_id() as Id;
    insert_post_content_tags(db_pool, post_content_id, tags).await?;

    Ok(post_content_id)
}

async fn insert_post_inner(db_pool: &MySqlPool, posted_by_user_id: Id) -> Result<MySqlQueryResult> {
    sqlx::query!(
        "
            INSERT INTO posts
            (
                posted_by,
                posted_at
            )
            VALUES
            (
                ?,
                NOW()
            )
            ",
        posted_by_user_id
    )
    .execute(db_pool)
    .await
}
