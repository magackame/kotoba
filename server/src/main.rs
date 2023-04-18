use actix_cors::Cors;
use actix_web::{get, web, App, HttpServer, Responder};
use dotenv::dotenv;
use jwt_simple::prelude::HS256Key;
use sqlx::mysql::{MySqlPool, MySqlPoolOptions};

mod db;
mod error;
mod jwt;
mod services;

async fn index() -> actix_web::Result<actix_files::NamedFile> {
    let file = if cfg!(debug_assertions) {
        actix_files::NamedFile::open("../web/public/index.html")?
    } else {
        actix_files::NamedFile::open("public/index.html")?
    };

    Ok(file)
}

pub struct State {
    db_pool: MySqlPool,
    jwt_private_key: HS256Key,
}

#[tokio::main]
async fn main() -> std::io::Result<()> {
    dotenv().expect("Failed to load `.env` file");

    let connection_string =
        std::env::var("DATABASE_URL").expect("$DATABASE_URL env var is not set");

    let db_pool = MySqlPoolOptions::new()
        .max_connections(5)
        .connect(&connection_string)
        .await
        .expect("Failed to connect to MySQL");

    let jwt_private_key = HS256Key::generate();

    HttpServer::new(move || {
        let cors = Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header();

        App::new()
            .wrap(cors)
            .app_data(web::Data::new(State {
                db_pool: db_pool.clone(),
                jwt_private_key: jwt_private_key.clone(),
            }))
            .service(services::sign_up::service)
            .service(services::sign_in::service)
            .service(services::post::create::service)
            .service(services::post::all::service)
            .service(services::post::feed::service)
            .service(services::post::fetch::service)
            .service(services::post::comments::fetch::service)
            .service(services::post::comments::create::service)
            .service(services::reauth::service)
            .service(services::user::fetch::service)
            .service(services::user::posts::service)
            .service(services::user::comments::service)
            .service(services::languages::fetch::service)
            .service(services::user::search::service)
            .service(services::post::bookmarks::service)
            .service(services::user::follows::service)
            .service(services::user::follows::fetch::service)
            .service(services::user::bookmarks::service)
            .service(services::post::edit::service)
            .service(services::post::edit::languages::service)
            .service(services::post::translate::languages::service)
            .service(services::post::translate::service)
            .service(services::user::translations::service)
            .service(if cfg!(debug_assertions) {
                actix_files::Files::new("/dist", "../web/public/dist")
            } else {
                actix_files::Files::new("/dist", "public/dist")
            })
            .default_service(web::route().to(index))
    })
    .bind(("0.0.0.0", 3000))?
    .run()
    .await
}
