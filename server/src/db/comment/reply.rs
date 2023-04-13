use crate::db::id::Id;
use crate::db::user::meta::Meta as UserMeta;
use serde::Serialize;

#[derive(Debug, Serialize)]
pub struct Reply {
    pub comment_id: Id,
    pub reply_to: UserMeta,
}
