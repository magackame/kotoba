use num::clamp;

pub const MIN_LIMIT: u64 = 1;
pub const MAX_LIMIT: u64 = 20;

#[derive(Debug, Copy, Clone)]
pub struct Page {
    limit: u64,
    offset: u64,
}

impl Page {
    pub fn new(limit: u64, offset: u64) -> Self {
        let limit = clamp(limit, MIN_LIMIT, MAX_LIMIT);

        Self { limit, offset }
    }

    pub fn get_limit(&self) -> u64 {
        self.limit
    }

    pub fn get_offset(&self) -> u64 {
        self.offset
    }
}
