use super::id::Id;
use super::post::status::Status as PostStatus;
use serde::Serialize;
use sqlx::mysql::MySqlPool;
use sqlx::Result;

#[derive(Debug, Serialize)]
pub struct Translation {
    pub post_content_id: Id,
    pub language_id: Id,
    pub language: String,
}

impl Translation {
    pub async fn fetch_by_post_id(db_pool: &MySqlPool, post_id: Id) -> Result<Vec<Translation>> {
        sqlx::query_as!(
            Translation,
            "
            SELECT
                post_contents.id AS post_content_id,
                languages.id AS language_id,
                name AS language
            FROM posts
                JOIN post_contents ON posts.id = post_contents.post_id
                JOIN languages ON post_contents.language_id = languages.id
            WHERE
                posts.id = ?
                AND status = ?
            ",
            post_id,
            PostStatus::Approved.as_str(),
        )
        .fetch_all(db_pool)
        .await
    }
}
