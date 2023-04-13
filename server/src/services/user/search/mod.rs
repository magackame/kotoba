use crate::db::page::Page;
use crate::error::Error;
use crate::State;
use actix_web::{post, web, HttpResponse};
use serde::Deserialize;

mod db;
use db::User;

#[derive(Debug, Deserialize)]
pub struct Request {
    pub query: String,
    pub limit: u64,
    pub offset: u64,
}

#[post("/api/user/search")]
pub async fn service(
    state: web::Data<State>,
    request: web::Json<Request>,
) -> Result<HttpResponse, Error> {
    let request = request.0;

    let page = Page::new(request.limit, request.offset);

    let page = User::find(&state.db_pool, &request.query, page).await?;

    Ok(HttpResponse::Ok().json(page))
}
