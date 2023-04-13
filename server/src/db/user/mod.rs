use super::id::Id;
use sqlx::mysql::{MySqlPool, MySqlQueryResult};
use sqlx::Result;
use uuid::Uuid;

pub mod handle;
pub mod meta;
pub mod role;

pub async fn update_retoken(db_pool: &MySqlPool, id: Id) -> Result<(String, MySqlQueryResult)> {
    let retoken = Uuid::new_v4().to_string();

    let result = sqlx::query!(
        "
        UPDATE users
        SET retoken = ?
        WHERE id = ?
        ",
        retoken,
        id,
    )
    .execute(db_pool)
    .await?;

    Ok((retoken, result))
}
