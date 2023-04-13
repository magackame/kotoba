use crate::db::id::Id;
use crate::error::Error;
use crate::State;
use actix_web::{
    post,
    web::{Data, Json},
    HttpResponse,
};
use serde::Deserialize;

mod db;
use db::fetch;

#[derive(Debug, Deserialize)]
pub struct Request {
    pub post_content_id: Id,
    pub query: String,
}

#[post("/api/post/edit/languages")]
pub async fn service(
    state: Data<State>,
    Json(request): Json<Request>,
) -> Result<HttpResponse, Error> {
    let languages = fetch(&state.db_pool, request.post_content_id, &request.query).await?;

    Ok(HttpResponse::Ok().json(languages))
}
