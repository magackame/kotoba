use crate::db::id::Id;
use crate::db::post::content::Content;
use crate::db::post::description::Description;
use crate::db::post::tags::Tags;
use crate::db::post::title::Title;
use crate::error::Error;
use crate::jwt;
use crate::State;
use actix_web::{post, web, HttpResponse};
use serde::{Deserialize, Serialize};

mod db;
use db::insert_post;

#[derive(Debug, Deserialize)]
pub struct Request {
    pub token: String,

    pub language_id: Id,
    pub title: String,
    pub description: String,
    pub tags: Vec<String>,
    pub content: String,
}

#[derive(Debug, Serialize)]
#[serde(tag = "tag")]
pub enum Response {
    Unauthorized,
    Success { post_content_id: Id },
}

#[post("/api/post/create")]
pub async fn service(
    state: web::Data<State>,
    request: web::Json<Request>,
) -> Result<HttpResponse, Error> {
    let request = request.0;

    let custom_claims = match jwt::auth(&state.jwt_private_key, &request.token) {
        Ok(custom_claims) => custom_claims,
        Err(_) => {
            return Ok(HttpResponse::Ok().json(Response::Unauthorized));
        }
    };

    if !custom_claims.role.can_post() {
        return Err(Error::Validation);
    }

    let title = Title::parse(request.title)?;
    let description = Description::parse(request.description)?;
    let tags = Tags::parse(request.tags)?;
    let content = Content::parse(request.content)?;

    // TODO: Update related fields
    // TODO: check upload limits

    let post_content_id = insert_post(
        &state.db_pool,
        custom_claims.id,
        request.language_id,
        &title,
        &description,
        &tags,
        &content,
    )
    .await?;

    Ok(HttpResponse::Ok().json(Response::Success { post_content_id }))
}
