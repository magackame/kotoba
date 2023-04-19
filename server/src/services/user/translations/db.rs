use crate::db::id::Id;
use crate::db::page::Page;
use crate::db::post::status::Status;
use crate::db::user::meta::Meta as UserMeta;
use chrono::NaiveDateTime;
use serde::Serialize;
use sqlx::mysql::MySqlPool;
use sqlx::Result;

#[derive(Debug, Serialize)]
pub struct Translation {
    pub post_id: Id,
    pub post_content_id: Id,
    pub language_id: Id,
    pub language: String,
    pub title: String,
    pub status: Status,

    pub posted_by: UserMeta,
    pub translated_by: UserMeta,

    pub posted_at: i64,
    pub translated_at: i64,
}

impl Translation {
    pub async fn fetch_page(
        db_pool: &MySqlPool,
        fetcher_user_id: Id,
        is_mine: bool,
        query: &str,
        page: Page,
    ) -> Result<Vec<Self>> {
        RawTranslation::fetch_page(db_pool, fetcher_user_id, is_mine, query, page)
            .await
            .map(|result| {
                result
                    .into_iter()
                    .map(|translation| translation.into())
                    .collect()
            })
    }
}

impl From<RawTranslation> for Translation {
    fn from(raw: RawTranslation) -> Self {
        Self {
            post_id: raw.post_id,
            post_content_id: raw.post_content_id,
            language_id: raw.language_id,
            language: raw.language,
            title: raw.title,
            // TODO: Better error handling
            status: Status::from_str(&raw.status).unwrap(),

            posted_by: UserMeta {
                id: raw.posted_by_id,
                handle: raw.posted_by_handle,
                profile_picture_file_name: raw.posted_by_profile_picture_file_name,
            },
            translated_by: UserMeta {
                id: raw.translated_by_id,
                handle: raw.translated_by_handle,
                profile_picture_file_name: raw.translated_by_profile_picture_file_name,
            },

            posted_at: raw.posted_at.timestamp_millis(),
            translated_at: raw.translated_at.timestamp_millis(),
        }
    }
}

#[derive(Debug)]
pub struct RawTranslation {
    pub post_id: Id,
    pub post_content_id: Id,
    pub language_id: Id,
    pub language: String,
    pub title: String,
    pub status: String,

    pub posted_by_id: Id,
    pub posted_by_handle: String,
    pub posted_by_profile_picture_file_name: Option<String>,

    pub translated_by_id: Id,
    pub translated_by_handle: String,
    pub translated_by_profile_picture_file_name: Option<String>,

    pub posted_at: NaiveDateTime,
    pub translated_at: NaiveDateTime,
}

impl RawTranslation {
    async fn fetch_page(
        db_pool: &MySqlPool,
        fetcher_user_id: Id,
        is_mine: bool,
        query: &str,
        page: Page,
    ) -> Result<Vec<Self>> {
        if is_mine {
            Self::fetch_mine_page(db_pool, fetcher_user_id, query, page).await
        } else {
            Self::fetch_others_page(db_pool, fetcher_user_id, query, page).await
        }
    }

    async fn fetch_mine_page(
        db_pool: &MySqlPool,
        fetcher_user_id: Id,
        query: &str,
        page: Page,
    ) -> Result<Vec<Self>> {
        let query = format!("%{query}%");

        sqlx::query_as!(
            Self,
            "
            SELECT
                posts.id AS post_id,
                post_contents.id AS post_content_id,
                post_contents.language_id,
                languages.name AS language,
                title,
                status,
                users_posted_by.id AS posted_by_id,
                users_posted_by.handle AS posted_by_handle,
                CONCAT(files_posted_by.id, \".\", files_posted_by.extension) AS posted_by_profile_picture_file_name,
                users_translated_by.id AS translated_by_id,
                users_translated_by.handle AS translated_by_handle,
                CONCAT(files_translated_by.id, \".\", files_translated_by.extension) AS translated_by_profile_picture_file_name,
                posted_at,
                translated_at
            FROM posts
                JOIN post_contents ON posts.id = post_contents.post_id
                JOIN languages ON post_contents.language_id = languages.id
                JOIN users AS users_posted_by ON posts.posted_by = users_posted_by.id
                LEFT JOIN files AS files_posted_by ON users_posted_by.profile_picture_file_id = files_posted_by.id
                JOIN users AS users_translated_by ON post_contents.translated_by = users_translated_by.id
                LEFT JOIN files AS files_translated_by ON users_translated_by.profile_picture_file_id = files_translated_by.id
            WHERE
                translated_by = ?
                AND title LIKE ?
            ORDER BY translated_at DESC
            LIMIT ? OFFSET ?
            ",
            fetcher_user_id,
            query,
            page.get_limit(),
            page.get_offset()
        )
        .fetch_all(db_pool)
        .await
    }

    async fn fetch_others_page(
        db_pool: &MySqlPool,
        fetcher_user_id: Id,
        query: &str,
        page: Page,
    ) -> Result<Vec<Self>> {
        let query = format!("%{query}%");

        sqlx::query_as!(
            Self,
            "
            SELECT
                posts.id AS post_id,
                post_contents.id AS post_content_id,
                post_contents.language_id,
                languages.name AS language,
                title,
                status,
                users_posted_by.id AS posted_by_id,
                users_posted_by.handle AS posted_by_handle,
                CONCAT(files_posted_by.id, \".\", files_posted_by.extension) AS posted_by_profile_picture_file_name,
                users_translated_by.id AS translated_by_id,
                users_translated_by.handle AS translated_by_handle,
                CONCAT(files_translated_by.id, \".\", files_translated_by.extension) AS translated_by_profile_picture_file_name,
                posted_at,
                translated_at
            FROM posts
                JOIN post_contents ON posts.id = post_contents.post_id
                JOIN languages ON post_contents.language_id = languages.id
                JOIN users AS users_posted_by ON posts.posted_by = users_posted_by.id
                LEFT JOIN files AS files_posted_by ON users_posted_by.profile_picture_file_id = files_posted_by.id
                JOIN users AS users_translated_by ON post_contents.translated_by = users_translated_by.id
                LEFT JOIN files AS files_translated_by ON users_translated_by.profile_picture_file_id = files_translated_by.id
            WHERE
                posted_by = ?
                AND translated_by != ?
                AND title LIKE ?
            LIMIT ? OFFSET ?
            ",
            fetcher_user_id,
            fetcher_user_id,
            query,
            page.get_limit(),
            page.get_offset()
        )
        .fetch_all(db_pool)
        .await
    }
}
