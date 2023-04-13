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
use db::Post;

#[derive(Debug, Deserialize)]
pub struct Request {
    pub token: Option<String>,

    pub post_content_id: Id,
}

#[derive(Debug, Serialize)]
#[serde(tag = "tag")]
pub enum Response {
    Unauthorized,
    Success { post: Option<Post> },
}

#[post("/api/post/fetch")]
pub async fn service(
    state: Data<State>,
    Json(request): Json<Request>,
) -> Result<HttpResponse, Error> {
    let fetcher_user_id = match jwt::get_fetcher_user_id(&state.jwt_private_key, &request.token) {
        Ok(fetcher_user_id) => fetcher_user_id,
        Err(_) => return Ok(HttpResponse::Ok().json(Response::Unauthorized)),
    };

    let post =
        Post::fetch_by_post_content_id(&state.db_pool, fetcher_user_id, request.post_content_id)
            .await?;

    Ok(HttpResponse::Ok().json(Response::Success { post }))
}
