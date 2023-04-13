use crate::db::comment::{Comment, RawComment};
use crate::db::id::Id;
use crate::db::page::Page;
use sqlx::mysql::MySqlPool;
use sqlx::Result;

pub async fn fetch_page(
    db_pool: &MySqlPool,
    user_id: Id,
    query: &str,
    page: Page,
) -> Result<Vec<Comment>> {
    let page = fetch_raw_page(db_pool, user_id, query, page).await?;

    let page = page
        .into_iter()
        .map(|raw_comment| raw_comment.into())
        .collect();

    Ok(page)
}

async fn fetch_raw_page(
    db_pool: &MySqlPool,
    user_id: Id,
    query: &str,
    page: Page,
) -> Result<Vec<RawComment>> {
    let query = format!("%{}%", query);

    sqlx::query_as!(
        RawComment,
        "
        SELECT
            comments.id,
            comments.post_content_id,
            comments.reply_to as reply_to_id,
            reply_to_users.id as reply_to_user_id,
            reply_to_users.handle as reply_to_handle,
            CONCAT(reply_to_files.id, \".\", reply_to_files.extension) AS reply_to_profile_picture_file_name,
            comments.content,
            posted_by_users.id as posted_by_id,
            posted_by_users.handle as posted_by_handle,
            CONCAT(posted_by_files.id, \".\", posted_by_files.extension) AS posted_by_profile_picture_file_name,
            comments.posted_at
        FROM comments
            LEFT JOIN comments AS reply_to ON comments.reply_to = reply_to.id 
            LEFT JOIN users AS reply_to_users ON reply_to.posted_by = reply_to_users.id
            LEFT JOIN files AS reply_to_files ON reply_to_users.profile_picture_file_id = reply_to_files.id
            JOIN users AS posted_by_users ON comments.posted_by = posted_by_users.id
            LEFT JOIN files AS posted_by_files ON posted_by_users.profile_picture_file_id = posted_by_files.id
        WHERE (comments.content LIKE ? OR reply_to_users.handle LIKE ?) AND comments.posted_by = ?
        LIMIT ? OFFSET ?
        ",
        query,
        query,
        user_id,
        page.get_limit(),
        page.get_offset()
    )
    .fetch_all(db_pool)
    .await
}
