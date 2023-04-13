use crate::db::format_as_subquery;
use crate::db::id::{Id, IdRow};
use crate::db::page::Page;
use crate::db::post::meta::Meta as PostMeta;
use crate::db::post::status::Status;
use sqlx::mysql::MySqlPool;
use sqlx::Result;

pub async fn fetch_page(
    db_pool: &MySqlPool,
    fetcher_language_ids: &Vec<Id>,
    fetcher_tag_ids: &Vec<Id>,
    query: &str,
    page: Page,
) -> Result<Vec<PostMeta>> {
    let query = format!("%{}%", query);

    let q = format!(
        "
        SELECT DISTINCT
            filtered_posts.id
        FROM
        (
            SELECT posts.id FROM posts
                JOIN post_contents ON posts.id = post_contents.post_id
                JOIN post_content_tags ON post_contents.id = post_content_tags.post_content_id
                JOIN users ON posts.posted_by = users.id
                LEFT JOIN files ON users.profile_picture_file_id = files.id
            WHERE
                status = ?
                AND (title LIKE ? OR post_contents.description LIKE ? OR content LIKE ?)
                AND language_id IN {}
                AND tag_id IN {}
            ORDER BY translated_at DESC
            LIMIT ? OFFSET ?
        ) AS filtered_posts
        ",
        format_as_subquery(fetcher_language_ids),
        format_as_subquery(fetcher_tag_ids)
    );

    let post_ids = sqlx::query_as::<_, IdRow>(&q)
        .bind(Status::Approved.as_str())
        .bind(&query)
        .bind(&query)
        .bind(&query)
        .bind(page.get_limit())
        .bind(page.get_offset())
        .fetch_all(db_pool)
        .await?
        .into_iter()
        .map(|row| row.id)
        .collect();

    let page =
        PostMeta::fetch_from_post_ids_with_best_language(db_pool, fetcher_language_ids, &post_ids)
            .await?;

    Ok(page)
}
