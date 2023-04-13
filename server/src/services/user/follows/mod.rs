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

pub mod fetch;

mod db;
use db::update_follow;

#[derive(Debug, Deserialize)]
pub struct Request {
    pub token: String,

    pub user_id: Id,
}

#[derive(Debug, Serialize)]
#[serde(tag = "tag")]
pub enum Response {
    Unauthorized,
    InvalidPermissions,
    Success,
}

#[post("/api/user/follows")]
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

    if !custom_claims.role.can_follow() {
        return Ok(HttpResponse::Ok().json(Response::InvalidPermissions));
    }

    update_follow(&state.db_pool, custom_claims.id, request.user_id).await?;

    Ok(HttpResponse::Ok().json(Response::Success))
}
