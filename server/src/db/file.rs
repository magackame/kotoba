use super::id::Id;
use sqlx::mysql::{MySqlPool, MySqlQueryResult};
use sqlx::Result;

#[derive(Debug, Copy, Clone, sqlx::Type)]
pub enum Extension {
    #[sqlx(rename = "jpeg")]
    Jpeg,
    #[sqlx(rename = "png")]
    Png,
    #[sqlx(rename = "webp")]
    Webp,
    #[sqlx(rename = "mp3")]
    Mp3,
    #[sqlx(rename = "mp4")]
    Mp4,
}

#[derive(Debug)]
pub struct File;

impl File {
    pub async fn insert(
        db_pool: &MySqlPool,
        original_file_name: Option<String>,
        extension: Extension,
        size: i32,
        uploaded_by: Id,
    ) -> Result<MySqlQueryResult> {
        sqlx::query!(
            "
            INSERT INTO files
            (
                original_file_name,
                extension,
                size,
                uploaded_by,
                uploaded_at
            )
            VALUES
            (
                ?,
                ?,
                ?,
                ?,
                DEFAULT
            )
            ",
            original_file_name,
            extension,
            size,
            uploaded_by
        )
        .execute(db_pool)
        .await
    }
}
