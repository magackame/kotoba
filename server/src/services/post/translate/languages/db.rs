use crate::db::id::Id;
use crate::db::language::Language;
use crate::db::post::status::Status as PostStatus;
use sqlx::mysql::MySqlPool;
use sqlx::Result;

pub const SUGGESTIONS_MAX_AMOUNT: u64 = 5;

pub async fn fetch(db_pool: &MySqlPool, post_id: Id, query: &str) -> Result<Vec<Language>> {
    let query = format!("%{}%", query);

    // TODO: Refactor all where clauses to begin on new line
    sqlx::query_as!(
        Language,
        "
            SELECT
                id,
                name
            FROM languages
            WHERE
                id NOT IN (
                    SELECT
                        language_id
                    FROM posts
                        JOIN post_contents ON posts.id = post_contents.post_id
                    WHERE 
                        posts.id = ?
                        AND status = ?
                )
                AND name LIKE ?
            LIMIT ?
            ",
        post_id,
        PostStatus::Approved.as_str(),
        query,
        SUGGESTIONS_MAX_AMOUNT
    )
    .fetch_all(db_pool)
    .await
}
