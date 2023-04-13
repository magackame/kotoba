use crate::db::id::Id;
use crate::db::post::tags::Tags;
use sqlx::mysql::{MySqlPool, MySqlQueryResult};
use sqlx::Result;

pub mod meta;
pub mod tags;

pub mod title;
use title::Title;

pub mod description;
use description::Description;

pub mod content;
use content::Content;

pub mod status;
use status::Status;

pub async fn insert_post_content(
    db_pool: &MySqlPool,
    post_id: Id,
    language_id: Id,
    title: &Title,
    description: &Description,
    content: &Content,
    status: Status,
    translated_by: Id,
) -> Result<MySqlQueryResult> {
    sqlx::query!(
        "
            INSERT INTO post_contents
            (
                post_id,
                language_id,
                title,
                description,
                content,
                status,
                translated_by,
                translated_at
            )
            VALUES
            (
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                NOW()
            )
            ",
        post_id,
        language_id,
        title.as_ref(),
        description.as_ref(),
        content.as_ref(),
        status.as_str(),
        translated_by
    )
    .execute(db_pool)
    .await
}

pub async fn insert_post_content_tags(
    db_pool: &MySqlPool,
    post_content_id: Id,
    tags: &Tags,
) -> Result<()> {
    // TODO: Batch this up!
    for tag in tags.as_ref() {
        let tag_id = match sqlx::query!(
            "
                SELECT
                    id
                FROM tags
                WHERE name = ?
                ",
            tag
        )
        .fetch_optional(db_pool)
        .await?
        {
            Some(row) => row.id,
            None => {
                let tag_insert_result = sqlx::query!(
                    "
                        INSERT INTO tags
                        (
                            name
                        )
                        VALUES
                        (
                            ?
                        )
                        ",
                    tag
                )
                .execute(db_pool)
                .await?;

                tag_insert_result.last_insert_id() as Id
            }
        };

        sqlx::query!(
            "
                INSERT INTO post_content_tags
                (
                    post_content_id,
                    tag_id
                )
                VALUES
                (
                    ?,
                    ?
                )
                ",
            post_content_id,
            tag_id
        )
        .execute(db_pool)
        .await?;
    }

    Ok(())
}
