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
use db::{fetch_page, is_bookmarks_private};

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

#[post("/api/user/bookmarks")]
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

    if is_bookmarks_private(&state.db_pool, request.user_id)
        .await?
        .unwrap_or(true)
    {
        return Ok(HttpResponse::Ok().json(Vec::<PostMeta>::new()));
    }

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
