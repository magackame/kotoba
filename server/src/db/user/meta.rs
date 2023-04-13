use crate::db::id::Id;
use serde::Serialize;

#[derive(Debug, Serialize)]
pub struct Meta {
    pub id: Id,
    pub handle: String,
    pub profile_picture_file_name: Option<String>,
}
