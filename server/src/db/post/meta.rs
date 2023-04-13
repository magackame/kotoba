use crate::db::id::Id;
use crate::db::tag::fetch_tags_by_post_content_id;
use crate::db::user::meta::Meta as UserMeta;
use chrono::NaiveDateTime;
use futures::TryStreamExt;
use serde::Serialize;
use sqlx::mysql::MySqlPool;
use sqlx::Result;
use std::collections::HashMap;

#[derive(Debug, Serialize)]
pub struct Meta {
    pub id: Id,
    pub post_content_id: Id,
    pub title: String,
    pub description: String,
    pub tags: Vec<String>,
    pub posted_by: UserMeta,
    pub posted_at: i64,
}

impl Meta {
    async fn fetch_from_raw(db_pool: &MySqlPool, raw: RawMeta) -> Result<Self> {
        let tags = fetch_tags_by_post_content_id(db_pool, raw.post_content_id).await?;

        let meta = Self {
            id: raw.id,
            post_content_id: raw.post_content_id,
            title: raw.title,
            description: raw.description,
            tags,
            posted_by: UserMeta {
                id: raw.posted_by_id,
                handle: raw.posted_by_handle,
                profile_picture_file_name: raw.posted_by_profile_picture_file_name,
            },
            posted_at: raw.posted_at.timestamp_millis(),
        };

        Ok(meta)
    }

    pub async fn fetch_from_post_ids_with_best_language(
        db_pool: &MySqlPool,
        fetcher_language_ids: &Vec<Id>,
        post_ids: &Vec<Id>,
    ) -> Result<Vec<Self>> {
        let language_max_priority = fetcher_language_ids.len();

        let mut language_priorities = HashMap::new();
        for (i, language_id) in fetcher_language_ids.iter().enumerate() {
            language_priorities.insert(*language_id, language_max_priority - i);
        }

        let mut post_metas = Vec::new();
        for post_id in post_ids {
            let post_raw_meta = RawMeta::fetch_with_best_language(
                db_pool,
                language_max_priority,
                &language_priorities,
                *post_id,
            )
            .await?;

            if let Some(post_raw_meta) = post_raw_meta {
                let post_meta = Meta::fetch_from_raw(db_pool, post_raw_meta).await?;

                post_metas.push(post_meta);
            }
        }

        Ok(post_metas)
    }
}

#[derive(Debug, sqlx::FromRow)]
pub struct RawMeta {
    pub id: Id,
    pub post_content_id: Id,
    pub language_id: Id,
    pub title: String,
    pub description: String,

    pub posted_by_id: Id,
    pub posted_by_handle: String,
    pub posted_by_profile_picture_file_name: Option<String>,

    pub posted_at: NaiveDateTime,
}

impl RawMeta {
    async fn fetch_with_best_language(
        db_pool: &MySqlPool,
        language_max_priority: usize,
        language_priorities: &HashMap<Id, usize>,
        post_id: Id,
    ) -> Result<Option<Self>> {
        let mut cursor = sqlx::query_as!(
            Self,
            "
            SELECT
                posts.id,
                post_contents.id AS post_content_id,
                language_id,
                title,
                post_contents.description,
                users.id as posted_by_id,
                users.handle as posted_by_handle,
                CONCAT(files.id, \".\", files.extension) AS posted_by_profile_picture_file_name,
                posted_at
            FROM posts
                JOIN post_contents ON posts.id = post_contents.post_id
                JOIN users ON posts.posted_by = users.id
                LEFT JOIN files ON users.profile_picture_file_id = files.id
            WHERE posts.id = ?
            ",
            post_id
        )
        .fetch(db_pool);

        let mut best = match cursor.try_next().await? {
            Some(post_raw_meta) => post_raw_meta,
            None => return Ok(None),
        };

        let mut best_language_priority = *language_priorities.get(&best.language_id).unwrap_or(&0);

        // Return early if the bestest possible language is already found
        if best_language_priority == language_max_priority {
            return Ok(Some(best));
        }

        while let Some(post_raw_meta) = cursor.try_next().await? {
            let language_priority = *language_priorities
                .get(&post_raw_meta.language_id)
                .unwrap_or(&0);

            if language_priority > best_language_priority {
                best = post_raw_meta;
                best_language_priority = *language_priorities.get(&best.language_id).unwrap_or(&0);

                // Return early if the bestest possible language is already found
                if best_language_priority == language_max_priority {
                    return Ok(Some(best));
                }
            }
        }

        Ok(Some(best))
    }
}
