use crate::error::Error;
use crate::State;
use actix_web::{
    post,
    web::{Data, Json},
    HttpResponse,
};
use serde::Deserialize;

mod db;
use db::find;

#[derive(Debug, Deserialize)]
pub struct Request {
    pub query: String,
}

#[post("/api/languages/fetch")]
pub async fn service(
    state: Data<State>,
    Json(request): Json<Request>,
) -> Result<HttpResponse, Error> {
    let languages = find(&state.db_pool, &request.query).await?;

    Ok(HttpResponse::Ok().json(languages))
}
