use crate::error::Error;
use crate::State;
use actix_web::{post, web, HttpResponse};
use serde::Deserialize;

mod db;
use db::find;

#[derive(Debug, Deserialize)]
pub struct Request {
    pub query: String,
}

#[post("/api/languages/fetch")]
pub async fn service(
    state: web::Data<State>,
    request: web::Json<Request>,
) -> Result<HttpResponse, Error> {
    let request = request.0;

    let languages = find(&state.db_pool, &request.query).await?;

    Ok(HttpResponse::Ok().json(languages))
}
