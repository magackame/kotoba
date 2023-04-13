use crate::db::comment::content::Content;
use crate::db::id::Id;
use crate::error::Error;
use crate::jwt;
use crate::State;
use actix_web::{
    post,
    web::{Data, Json},
    HttpResponse,
};
use serde::{Deserialize, Serialize};

mod db;
use db::insert_comment;

#[derive(Debug, Deserialize)]
pub struct Request {
    pub token: String,

    pub post_content_id: Id,
    pub reply_to: Option<Id>,
    pub content: String,
}

#[derive(Debug, Serialize)]
#[serde(tag = "tag")]
pub enum Response {
    Unauthorized,
    Success,
}

#[post("/api/post/comments/create")]
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

    if !custom_claims.role.can_comment() {
        return Err(Error::Validation);
    }

    let content = Content::parse(request.content)?;

    // TODO: Update related fields
    // TODO: check upload limits

    insert_comment(
        &state.db_pool,
        request.post_content_id,
        request.reply_to,
        &content,
        custom_claims.id,
    )
    .await?;

    Ok(HttpResponse::Ok().json(Response::Success))
}
