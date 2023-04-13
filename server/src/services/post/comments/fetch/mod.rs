use crate::db::id::Id;
use crate::db::page::Page;
use crate::error::Error;
use crate::State;
use actix_web::{
    post,
    web::{Data, Json},
    HttpResponse,
};
use serde::Deserialize;

mod db;
use db::fetch_page;

#[derive(Debug, Deserialize)]
pub struct Request {
    pub post_content_id: Id,
    pub query: String,
    pub limit: u64,
    pub offset: u64,
}

#[post("/api/post/comments/fetch")]
pub async fn service(
    state: Data<State>,
    Json(request): Json<Request>,
) -> Result<HttpResponse, Error> {
    let page = Page::new(request.limit, request.offset);

    let page = fetch_page(
        &state.db_pool,
        request.post_content_id,
        &request.query,
        page,
    )
    .await?;

    Ok(HttpResponse::Ok().json(page))
}
