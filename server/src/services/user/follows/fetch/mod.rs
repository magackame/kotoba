use crate::db::id::Id;
use crate::db::page::Page;
use crate::db::user::meta::Meta as UserMeta;
use crate::error::Error;
use crate::State;
use actix_web::{
    post,
    web::{Data, Json},
    HttpResponse,
};
use serde::Deserialize;

mod db;
use db::{fetch_page, is_following_private};

#[derive(Debug, Deserialize)]
pub struct Request {
    pub user_id: Id,
    pub query: String,
    pub limit: u64,
    pub offset: u64,
}

#[post("/api/user/follows/fetch")]
pub async fn service(
    state: Data<State>,
    Json(request): Json<Request>,
) -> Result<HttpResponse, Error> {
    if is_following_private(&state.db_pool, request.user_id)
        .await?
        .unwrap_or(true)
    {
        return Ok(HttpResponse::Ok().json(Vec::<UserMeta>::new()));
    }

    let page = Page::new(request.limit, request.offset);

    let page = fetch_page(&state.db_pool, request.user_id, &request.query, page).await?;

    Ok(HttpResponse::Ok().json(page))
}
