use crate::db::id::Id;
use crate::db::language::fetch_user_language_ids;
use crate::db::page::Page;
use crate::db::post::meta::Meta as PostMeta;
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
use db::fetch_page;

#[derive(Debug, Deserialize)]
pub struct Request {
    pub preferences: Preferences,

    pub user_id: Id,
    pub query: String,
    pub limit: u64,
    pub offset: u64,
}

#[derive(Debug, Deserialize)]
#[serde(tag = "tag")]
pub enum Preferences {
    Unauthorized { language_ids: Vec<Id> },
    Authorized { token: String },
}

#[derive(Debug, Serialize)]
#[serde(tag = "tag")]
pub enum Response {
    Unauthorized,
    Success { page: Vec<PostMeta> },
}

#[post("/api/user/posts")]
pub async fn service(
    state: Data<State>,
    Json(request): Json<Request>,
) -> Result<HttpResponse, Error> {
    let fetcher_language_ids = match request.preferences {
        Preferences::Unauthorized { language_ids } => language_ids,
        Preferences::Authorized { token } => {
            let fetcher_user_id = match jwt::auth(&state.jwt_private_key, &token) {
                Ok(custom_claims) => custom_claims.id,
                Err(_) => return Ok(HttpResponse::Ok().json(Response::Unauthorized)),
            };

            fetch_user_language_ids(&state.db_pool, fetcher_user_id).await?
        }
    };

    let page = Page::new(request.limit, request.offset);

    let page = fetch_page(
        &state.db_pool,
        &fetcher_language_ids,
        request.user_id,
        &request.query,
        page,
    )
    .await?;

    Ok(HttpResponse::Ok().json(Response::Success { page }))
}
