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
use db::User;

#[derive(Debug, Deserialize)]
pub struct Request {
    pub token: Option<String>,
    pub user_id: Id,
}

#[derive(Debug, Serialize)]
#[serde(tag = "tag")]
pub enum Response {
    Unauthorized,
    Success { user: Option<User> },
}

#[post("/api/user/fetch")]
pub async fn service(
    state: Data<State>,
    Json(request): Json<Request>,
) -> Result<HttpResponse, Error> {
    let fetcher_user_id = match jwt::get_fetcher_user_id(&state.jwt_private_key, &request.token) {
        Ok(fetcher_user_id) => fetcher_user_id,
        Err(_) => return Ok(HttpResponse::Ok().json(Response::Unauthorized)),
    };

    let user = User::fetch_by_id(&state.db_pool, fetcher_user_id, request.user_id).await?;

    Ok(HttpResponse::Ok().json(Response::Success { user }))
}
