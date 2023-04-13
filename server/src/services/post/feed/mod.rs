use crate::db::id::Id;
use crate::db::language::fetch_user_language_ids;
use crate::db::page::Page;
use crate::db::post::meta::Meta as PostMeta;
use crate::db::tag::fetch_user_tag_ids;
use crate::error::Error;
use crate::jwt;
use crate::State;
use actix_web::{post, web, HttpResponse};
use serde::{Deserialize, Serialize};

mod db;
use db::fetch_page;

#[derive(Debug, Deserialize)]
pub struct Request {
    pub preferences: Preferences,

    pub query: String,
    pub limit: u64,
    pub offset: u64,
}

#[derive(Debug, Deserialize)]
#[serde(tag = "tag")]
pub enum Preferences {
    Unauthorized {
        language_ids: Vec<Id>,
        tag_ids: Vec<Id>,
    },
    Authorized {
        token: String,
    },
}

#[derive(Debug, Serialize)]
#[serde(tag = "tag")]
pub enum Response {
    Unauthorized,
    Success { page: Vec<PostMeta> },
}

#[post("/api/post/feed")]
pub async fn service(
    state: web::Data<State>,
    request: web::Json<Request>,
) -> Result<HttpResponse, Error> {
    let request = request.0;

    let (fetcher_language_ids, fetcher_tag_ids) = match request.preferences {
        Preferences::Unauthorized {
            language_ids,
            tag_ids,
        } => (language_ids, tag_ids),
        Preferences::Authorized { token } => {
            let fetcher_user_id = match jwt::auth(&state.jwt_private_key, &token) {
                Ok(custom_claims) => custom_claims.id,
                Err(_) => return Ok(HttpResponse::Ok().json(Response::Unauthorized)),
            };

            let language_ids = fetch_user_language_ids(&state.db_pool, fetcher_user_id).await?;
            let tag_ids = fetch_user_tag_ids(&state.db_pool, fetcher_user_id).await?;

            (language_ids, tag_ids)
        }
    };

    let page = Page::new(request.limit, request.offset);

    let page = fetch_page(
        &state.db_pool,
        &fetcher_language_ids,
        &fetcher_tag_ids,
        &request.query,
        page,
    )
    .await?;

    Ok(HttpResponse::Ok().json(Response::Success { page }))
}
