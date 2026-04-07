use serde::{Deserialize, Serialize};

/// Full todo record (GET response).
#[derive(Default, Debug, Clone, Deserialize, Serialize, PartialEq)]
#[serde(default)]
pub struct Todo {
    pub id: Option<String>,
    pub title: String,
    pub completed: i64,
    pub created: Option<i64>,
    pub updated: Option<i64>,
}

/// Body for POST /api/records/v1/todos
#[derive(Debug, Serialize)]
pub struct NewTodo {
    pub title: String,
    pub completed: i64,
}

/// Body for PATCH /api/records/v1/todos/:id
#[derive(Debug, Serialize)]
pub struct UpdateTodo {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub title: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub completed: Option<i64>,
}
