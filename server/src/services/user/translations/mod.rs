use crate::db::page::Page;
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
use db::Translation;

#[derive(Debug, Deserialize)]
pub struct Request {
    pub token: String,

    pub is_mine: bool,
    pub query: String,
    pub limit: u64,
    pub offset: u64,
}

#[derive(Debug, Serialize)]
#[serde(tag = "tag")]
pub enum Response {
    Unauthorized,
    Success { page: Vec<Translation> },
}

#[post("/api/user/translations")]
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

    let page = Page::new(request.limit, request.offset);

    let page = Translation::fetch_page(
        &state.db_pool,
        custom_claims.id,
        request.is_mine,
        &request.query,
        page,
    )
    .await?;

    Ok(HttpResponse::Ok().json(Response::Success { page }))
}
