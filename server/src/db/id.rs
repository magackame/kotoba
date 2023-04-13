pub type Id = i32;

#[derive(Debug, sqlx::FromRow)]
pub struct IdRow {
    pub id: Id,
}
