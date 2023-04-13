pub mod comment;
pub mod file;
pub mod id;
pub mod language;
pub mod page;
pub mod post;
pub mod tag;
pub mod translation;
pub mod user;

pub fn format_as_subquery(ids: &Vec<id::Id>) -> String {
    // TODO: more elegant solution
    if ids.is_empty() {
        return "(0)".to_owned();
    }

    let mut s = "(".to_owned();

    for i in 0..ids.len() {
        s += &ids[i].to_string();

        if i != ids.len() - 1 {
            s += ", ";
        }
    }

    s += ")";

    s
}
