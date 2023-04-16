use crate::db::user::handle::Handle;
use crate::error::Error;
use crate::State;
use actix_web::{
    post,
    web::{Data, Json},
    HttpResponse,
};
use argon2::{
    password_hash::{rand_core::OsRng, PasswordHasher, SaltString},
    Argon2,
};
use serde::{Deserialize, Serialize};

mod db;
use db::User;

#[derive(Debug, Deserialize)]
pub struct Request {
    pub handle: String,

    pub email: String,
    pub password: String,
}

#[derive(Debug, Serialize)]
#[serde(tag = "tag")]
pub enum Response {
    HandleAlreadyTaken,
    EmailAlreadyTaken,
    InvalidEmail,
    Success,
}

#[post("/api/sign-up")]
pub async fn service(
    state: Data<State>,
    Json(request): Json<Request>,
) -> Result<HttpResponse, Error> {
    if User::exists_by_handle(&state.db_pool, &request.handle).await? {
        return Ok(HttpResponse::Ok().json(Response::HandleAlreadyTaken));
    }

    if User::exists_by_email(&state.db_pool, &request.email).await? {
        return Ok(HttpResponse::Ok().json(Response::EmailAlreadyTaken));
    }

    // TODO: Validate email through letter

    let handle = Handle::parse(request.handle)?;

    let salt = SaltString::generate(&mut OsRng);

    let argon2 = Argon2::default();

    let password_hash = argon2
        .hash_password(request.password.as_bytes(), &salt)?
        .to_string();

    User::insert(&state.db_pool, &handle, &request.email, &password_hash).await?;

    Ok(HttpResponse::Ok().json(Response::Success))
}
