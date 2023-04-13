use crate::db::id::{Id, IdRow};
use crate::db::page::Page;
use crate::db::post::meta::Meta as PostMeta;
use crate::db::post::status::Status;
use sqlx::mysql::MySqlPool;
use sqlx::Result;

pub async fn fetch_page(
    db_pool: &MySqlPool,
    fetcher_language_ids: &Vec<Id>,
    query: &str,
    page: Page,
) -> Result<Vec<PostMeta>> {
    let query = format!("%{}%", query);

    let post_ids = sqlx::query_as!(
        IdRow,
        "
        SELECT DISTINCT
            filtered_posts.id
        FROM
        (
            SELECT posts.id FROM posts
                JOIN post_contents ON posts.id = post_contents.post_id
                JOIN users ON posts.posted_by = users.id
                LEFT JOIN files ON users.profile_picture_file_id = files.id
            WHERE
                status = ?
                AND (title LIKE ? OR post_contents.description LIKE ? OR content LIKE ?)
            ORDER BY translated_at DESC
            LIMIT ? OFFSET ?
        ) AS filtered_posts
        ",
        Status::Approved.as_str(),
        query,
        query,
        query,
        page.get_limit(),
        page.get_offset(),
    )
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
