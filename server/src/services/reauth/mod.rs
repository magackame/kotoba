use super::sign_in::Response;
use crate::db::user::meta::Meta as UserMeta;
use crate::db::user::role::Role as UserRole;
use crate::db::user::update_retoken;
use crate::error::Error;
use crate::jwt;
use crate::State;
use actix_web::{
    post,
    web::{Data, Json},
    HttpResponse,
};
use serde::Deserialize;

mod db;
use db::User;

#[derive(Debug, Deserialize)]
pub struct Request {
    retoken: String,
}

#[post("/api/reauth")]
pub async fn service(
    state: Data<State>,
    Json(request): Json<Request>,
) -> Result<HttpResponse, Error> {
    let user = match User::fetch_by_retoken(&state.db_pool, &request.retoken).await? {
        Some(user_id) => user_id,
        None => {
            return Ok(HttpResponse::Ok().json(Response::Unauthorized));
        }
    };

    let role = UserRole::from_str(&user.role)?;

    let token = jwt::create(&state.jwt_private_key, user.id, role)?;

    let (retoken, _) = update_retoken(&state.db_pool, user.id).await?;

    Ok(HttpResponse::Ok().json(Response::Authorized {
        token,
        retoken,

        user_meta: UserMeta {
            id: user.id,
            handle: user.handle,
            profile_picture_file_name: user.profile_picture_file_name,
        },
    }))
}
