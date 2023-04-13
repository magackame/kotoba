use crate::db::id::Id;
use crate::db::page::Page;
use crate::db::user::meta::Meta as UserMeta;
use sqlx::mysql::MySqlPool;
use sqlx::Result;

pub async fn is_following_private(db_pool: &MySqlPool, user_id: Id) -> Result<Option<bool>> {
    #[derive(Debug)]
    struct User {
        is_following_private: i8,
    }

    sqlx::query_as!(
        User,
        "
        SELECT
            is_following_private
        FROM users
        WHERE id = ?
        ",
        user_id
    )
    .fetch_optional(db_pool)
    .await
    .map(|result| result.map(|user| user.is_following_private != 0))
}

pub async fn fetch_page(
    db_pool: &MySqlPool,
    user_id: Id,
    query: &str,
    page: Page,
) -> Result<Vec<UserMeta>> {
    let query = format!("%{}%", query);

    sqlx::query_as!(
        UserMeta,
        "
            SELECT
                users.id,
                handle,
                CONCAT(files.id, \".\", files.extension) AS profile_picture_file_name
            FROM users
                LEFT JOIN files ON users.profile_picture_file_id = files.id
            WHERE users.id IN (SELECT followed_user_id FROM followers WHERE follower_user_id = ?)
                AND (handle LIKE ? OR full_name LIKE ? OR description LIKE ?)
            LIMIT ? OFFSET ?
            ",
        user_id,
        query,
        query,
        query,
        page.get_limit(),
        page.get_offset(),
    )
    .fetch_all(db_pool)
    .await
}
