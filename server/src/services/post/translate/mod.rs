use crate::db::id::Id;
use crate::db::post::content::Content;
use crate::db::post::description::Description;
use crate::db::post::status::Status as PostStatus;
use crate::db::post::tags::Tags;
use crate::db::post::title::Title;
use crate::db::post::{insert_post_content, insert_post_content_tags};
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
use db::is_posted_by;

#[derive(Debug, Deserialize)]
pub struct Request {
    pub token: String,

    pub post_id: Id,
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

#[post("/api/post/translate")]
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

    if !custom_claims.role.can_translate_posts() {
        return Err(Error::Validation);
    }

    let title = Title::parse(request.title)?;
    let description = Description::parse(request.description)?;
    let tags = Tags::parse(request.tags)?;
    let content = Content::parse(request.content)?;

    // TODO: Update related fields
    // TODO: check upload limits

    let status = if is_posted_by(&state.db_pool, request.post_id, custom_claims.id).await? {
        PostStatus::Approved
    } else {
        PostStatus::Pending
    };

    let post_content_id = insert_post_content(
        &state.db_pool,
        request.post_id,
        request.language_id,
        &title,
        &description,
        &content,
        status,
        custom_claims.id,
    )
    .await?;

    let post_content_id = post_content_id.last_insert_id() as Id;

    insert_post_content_tags(&state.db_pool, post_content_id, &tags).await?;

    Ok(HttpResponse::Ok().json(Response::Success { post_content_id }))
}
