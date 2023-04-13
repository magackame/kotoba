use super::id::{Id, IdRow};
use sqlx::mysql::MySqlPool;
use sqlx::Result;

#[derive(Debug)]
struct Tag {
    pub name: String,
}

pub async fn fetch_tags_by_post_content_id(
    db_pool: &MySqlPool,
    post_content_id: Id,
) -> Result<Vec<String>> {
    sqlx::query_as!(
        Tag,
        "
        SELECT
            name
        FROM post_contents
            JOIN post_content_tags ON post_contents.id = post_content_tags.post_content_id
            JOIN tags ON post_content_tags.tag_id = tags.id
        WHERE post_contents.id = ?
        ",
        post_content_id
    )
    .fetch_all(db_pool)
    .await
    .map(|tags| tags.into_iter().map(|tag| tag.name).collect())
}

pub async fn fetch_user_tag_ids(db_pool: &MySqlPool, user_id: Id) -> Result<Vec<Id>> {
    sqlx::query_as!(
        IdRow,
        "
        SELECT
            id
        FROM user_tags
        WHERE user_id = ?
        ",
        user_id
    )
    .fetch_all(db_pool)
    .await
    .map(|id_rows| id_rows.into_iter().map(|id_row| id_row.id).collect())
}
