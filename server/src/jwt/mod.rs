use crate::db::id::Id;
use crate::db::user::role::Role as UserRole;
use jwt_simple::prelude::*;
use jwt_simple::Error;
use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize)]
pub struct CustomClaims {
    pub id: Id,
    pub role: UserRole,
}

pub fn create(jwt_private_key: &HS256Key, id: Id, role: UserRole) -> Result<String, Error> {
    let custom_claims = CustomClaims { id, role };

    let claims = Claims::with_custom_claims(custom_claims, Duration::from_secs(5));

    jwt_private_key.authenticate(claims)
}

pub fn auth(jwt_private_key: &HS256Key, token: &str) -> Result<CustomClaims, Error> {
    let mut options = VerificationOptions::default();
    options.time_tolerance = None;

    jwt_private_key
        .verify_token::<CustomClaims>(token, Some(options))
        .map(|claims| claims.custom)
}

pub fn get_fetcher_user_id(
    jwt_private_key: &HS256Key,
    token: &Option<String>,
) -> Result<Option<Id>, Error> {
    token
        .as_ref()
        .map(|token| auth(jwt_private_key, token).map(|custom_claims| custom_claims.id))
        .transpose()
}
