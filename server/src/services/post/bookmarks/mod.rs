use crate::db::id::Id;
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
use db::update_bookmark;

#[derive(Debug, Deserialize)]
pub struct Request {
    pub token: String,

    pub post_id: Id,
}

#[derive(Debug, Serialize)]
#[serde(tag = "tag")]
pub enum Response {
    Unauthorized,
    Success,
}

#[post("/api/post/bookmarks")]
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

    if !custom_claims.role.can_bookmark() {
        return Err(Error::Validation);
    }

    update_bookmark(&state.db_pool, custom_claims.id, request.post_id).await?;

    Ok(HttpResponse::Ok().json(Response::Success))
}
