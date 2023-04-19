use crate::db::id::Id;
use crate::db::post::status::Status as PostStatus;
use crate::error::Error;
use crate::jwt;
use crate::State;
use actix_web::{
    post,
    web::{Data, Json},
    HttpResponse,
};
use serde::{Deserialize, Serialize};

mod db;
use db::{is_posted_by, update_status};

#[derive(Debug, Deserialize)]
pub struct Request {
    pub token: String,

    pub post_content_id: Id,
    pub status: PostStatus,
}

#[derive(Debug, Serialize)]
#[serde(tag = "tag")]
pub enum Response {
    Unauthorized,
    Success,
}

#[post("/api/post/translations/status")]
pub async fn service(
    state: Data<State>,
    Json(request): Json<Request>,
) -> Result<HttpResponse, Error> {
    let custom_claims = match jwt::auth(&state.jwt_private_key, &request.token) {
        Ok(custom_claims) => custom_claims,
        Err(_) => {
            return Ok(HttpResponse::Ok().json(Response::Unauthorized));
        }
    };

    if !custom_claims.role.can_manage_translations() {
        return Err(Error::Validation);
    }

    if !is_posted_by(&state.db_pool, request.post_content_id, custom_claims.id).await? {
        return Err(Error::Validation);
    }

    update_status(&state.db_pool, request.post_content_id, request.status).await?;

    Ok(HttpResponse::Ok().json(Response::Success))
}
