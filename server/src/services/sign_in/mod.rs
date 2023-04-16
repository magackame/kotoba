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
use argon2::{
    password_hash::{PasswordHash, PasswordVerifier},
    Argon2,
};
use serde::{Deserialize, Serialize};

mod db;
use db::User;

#[derive(Debug, Deserialize)]
pub struct Request {
    pub email: String,
    pub password: String,
}

#[derive(Debug, Serialize)]
#[serde(tag = "tag")]
pub enum Response {
    Unauthorized,
    Authorized {
        token: String,
        retoken: String,

        user_meta: UserMeta,
    },
}

#[post("/api/sign-in")]
pub async fn service(
    state: Data<State>,
    Json(request): Json<Request>,
) -> Result<HttpResponse, Error> {
    let user = match User::fetch_by_email(&state.db_pool, &request.email).await? {
        Some(user) => user,
        None => {
            return Ok(HttpResponse::Ok().json(Response::Unauthorized));
        }
    };

    let parsed_hash = PasswordHash::new(&user.password).map_err(|_| Error::Argon2)?;

    if let Err(_) = Argon2::default().verify_password(request.password.as_bytes(), &parsed_hash) {
        return Ok(HttpResponse::Ok().json(Response::Unauthorized));
    }

    // let role = UserRole::from_str(&user.role)?;

    let token = jwt::create(&state.jwt_private_key, user.id, user.role)?;

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
