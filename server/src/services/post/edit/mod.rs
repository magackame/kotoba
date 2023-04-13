use crate::db::id::Id;
use crate::db::post::content::Content;
use crate::db::post::description::Description;
use crate::db::post::tags::Tags;
use crate::db::post::title::Title;
use crate::error::Error;
use crate::jwt;
use crate::State;
use actix_web::{
    post,
    web::{Data, Json},
    HttpResponse,
};
use serde::{Deserialize, Serialize};

pub mod languages;

mod db;
use db::{is_posted_by, update_post};

#[derive(Debug, Deserialize)]
pub struct Request {
    pub token: String,

    pub post_content_id: Id,
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
    Success,
}

#[post("/api/post/edit")]
pub async fn service(
    state: Data<State>,
    Json(request): Json<Request>,
) -> Result<HttpResponse, Error> {
    let custom_claims = match jwt::auth(&state.jwt_private_key, &request.token) {
        Ok(custom_claims) => custom_claims,
        Err(_) => {
            return Ok(HttpResponse::Ok().json(Response::Unauthorized));
        }
    };

    if !is_posted_by(&state.db_pool, request.post_content_id, custom_claims.id).await? {
        return Err(Error::Validation);
    }

    if !custom_claims.role.can_edit_posts() {
        return Err(Error::Validation);
    }

    let title = Title::parse(request.title)?;
    let description = Description::parse(request.description)?;
    let tags = Tags::parse(request.tags)?;
    let content = Content::parse(request.content)?;

    // TODO: Update related fields
    // TODO: check upload limits

    update_post(
        &state.db_pool,
        request.post_content_id,
        request.language_id,
        &title,
        &description,
        &tags,
        &content,
    )
    .await?;

    Ok(HttpResponse::Ok().json(Response::Success))
}
