# kotoba

A sort of Medium clone with multilanguage support

Front-end in [Elm](https://elm-lang.org/) using [elm-spa](https://www.elm-spa.dev/)

Back-end in [Rust](https://www.rust-lang.org/) using [actix-web](https://actix.rs/) and
[sqlx](https://crates.io/crates/sqlx)

## Features

- Create posts
- Translate posts
- Comment on posts
- Fully usable without an account
- Set preffered tags and languages
- Fulltext search
- Follow people to get their posts in your feed 
- Bookmark favorite posts

## How to build

You will need:

- Rust (`rustup`)
- Elm (`elm`)
- elm-spa (`elm-spa`)
- MySQL

1. `git clone git@github.com:magackame/kotoba.git`
2. `cd kotoba/web`
3. `elm-spa build`
4. `cd ../server`
5. `mysql -u user -p < db/scheme.sql`
    - MySQL must not contain a db named `kotoba`
    - Substitute `user` with MySQL username (This user must be able to create databases/tables)
    - Enter the user's password when prompted to
6. `cp dotenv-example .env`
    - In `export DATABASE_URL=mysql://user:password@localhost:3306/kotoba` substitute `user` and `password` with your MySQL credentials
7. `cargo build --release`
8. `cd ../..`
9. `mkdir kotoba-app`
10. `cp -r kotoba/web/public kotoba-app/public`
11. `cp kotoba/server/.env kotoba-app/.env`
12. `cp kotoba/server/target/release/server kotoba-app/server`

You now have a working application in `kotoba-app`

Just go `cd kotoba-app` and `./server`

Open a browser and go to `localhost:3000`

Tested on follwing versions (`Ubuntu 22.04.2 LTS x86_64`):

- `rustc` (`1.67.1`)
- `elm` (`0.19.1`)
- `elm-spa` (`6.0.4`)
- `MySQL` (`8.0.32`)

## WIP

- Monolithic architecture
- Horrible fulltext search implementation (just a `LIKE '%query%'` query)
- No testing
- No build script
- Quirky website behaviour
- A sprinkle of other `TODO`s in code