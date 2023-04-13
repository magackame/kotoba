use crate::db::id::Id;
use crate::db::post::status::Status;
use crate::db::tag::fetch_tags_by_post_content_id;
use crate::db::translation::Translation;
use crate::db::user::meta::Meta as UserMeta;
use chrono::NaiveDateTime;
use serde::Serialize;
use sqlx::mysql::MySqlPool;
use sqlx::Result;

#[derive(Debug, Serialize)]
pub struct Post {
    pub id: Id,
    pub post_content_id: Id,
    pub language_id: Id,
    pub language: String,
    pub translations: Vec<Translation>,
    pub title: String,
    pub description: String,
    pub tags: Vec<String>,
    pub content: String,

    pub posted_by: UserMeta,
    pub translated_by: UserMeta,

    pub posted_at: i64,
    pub translated_at: i64,

    pub is_bookmarked: bool,
}

impl Post {
    pub async fn fetch_by_post_content_id(
        db_pool: &MySqlPool,
        fetcher_user_id: Option<Id>,
        post_content_id: Id,
    ) -> Result<Option<Self>> {
        let fetcher_user_id = fetcher_user_id.unwrap_or(0);

        let raw_post = match RawPost::fetch_by_post_content_id(db_pool, post_content_id).await? {
            Some(raw_post) => raw_post,
            None => return Ok(None),
        };

        let translations = Translation::fetch_by_post_id(db_pool, raw_post.id).await?;
        let tags = fetch_tags_by_post_content_id(db_pool, raw_post.post_content_id).await?;

        let is_bookmarked = is_bookmarked(db_pool, fetcher_user_id, raw_post.id).await?;

        let post = Self {
            id: raw_post.id,
            post_content_id: raw_post.post_content_id,
            language_id: raw_post.language_id,
            language: raw_post.language,
            translations,
            title: raw_post.title,
            description: raw_post.description,
            tags,
            content: raw_post.content,

            posted_by: UserMeta {
                id: raw_post.posted_by_id,
                handle: raw_post.posted_by_handle,
                profile_picture_file_name: raw_post.posted_by_profile_picture_file_name,
            },
            translated_by: UserMeta {
                id: raw_post.translated_by_id,
                handle: raw_post.translated_by_handle,
                profile_picture_file_name: raw_post.translated_by_profile_picture_file_name,
            },

            posted_at: raw_post.posted_at.timestamp_millis(),
            translated_at: raw_post.translated_at.timestamp_millis(),

            is_bookmarked,
        };

        Ok(Some(post))
    }
}

#[derive(Debug)]
struct RawPost {
    pub id: Id,
    pub post_content_id: Id,
    pub language_id: Id,
    pub language: String,
    pub title: String,
    pub description: String,
    pub content: String,

    pub posted_by_id: Id,
    pub posted_by_handle: String,
    pub posted_by_profile_picture_file_name: Option<String>,

    pub translated_by_id: Id,
    pub translated_by_handle: String,
    pub translated_by_profile_picture_file_name: Option<String>,

    pub posted_at: NaiveDateTime,
    pub translated_at: NaiveDateTime,
}

impl RawPost {
    async fn fetch_by_post_content_id(
        db_pool: &MySqlPool,
        post_content_id: Id,
    ) -> Result<Option<Self>> {
        sqlx::query_as!(
            Self,
            "
            SELECT
                posts.id,
                post_contents.id as post_content_id,
                post_contents.language_id,
                languages.name AS language,
                title,
                post_contents.description,
                content,
                users_posted_by.id as posted_by_id,
                users_posted_by.handle as posted_by_handle,
                CONCAT(files_posted_by.id, \".\", files_posted_by.extension) AS posted_by_profile_picture_file_name,
                users_translated_by.id as translated_by_id,
                users_translated_by.handle as translated_by_handle,
                CONCAT(files_translated_by.id, \".\", files_translated_by.extension) AS translated_by_profile_picture_file_name,
                posted_at,
                translated_at
            FROM posts
                JOIN post_contents ON posts.id = post_contents.post_id
                JOIN languages ON post_contents.language_id = languages.id
                JOIN users as users_posted_by ON posts.posted_by = users_posted_by.id
                LEFT JOIN files as files_posted_by ON users_posted_by.profile_picture_file_id = files_posted_by.id
                JOIN users as users_translated_by ON post_contents.translated_by = users_translated_by.id
                LEFT JOIN files as files_translated_by ON users_translated_by.profile_picture_file_id = files_translated_by.id
            WHERE status = ? AND post_contents.id = ?
            ",
            Status::Approved.as_str(),
            post_content_id,
        )
        .fetch_optional(db_pool)
        .await
    }
}

async fn is_bookmarked(db_pool: &MySqlPool, fetcher_user_id: Id, post_id: Id) -> Result<bool> {
    sqlx::query!(
        "
        SELECT
            id
        FROM bookmarks
        WHERE user_id = ? AND post_id = ?
        ",
        fetcher_user_id,
        post_id
    )
    .fetch_optional(db_pool)
    .await
    .map(|result| result.is_some())
}
