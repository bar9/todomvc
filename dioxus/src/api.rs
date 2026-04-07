use gloo::net::http::Request;
use serde::{Deserialize, Serialize};

pub const TRAILBASE_URL: &str = match option_env!("TRAILBASE_URL") {
    Some(url) => url,
    None => "http://localhost:4000",
};

#[derive(Debug, Deserialize)]
#[allow(dead_code)]
pub struct ListResponse<T> {
    pub cursor: Option<String>,
    pub records: Vec<T>,
}

#[derive(Debug, Deserialize)]
#[allow(dead_code)]
pub struct CreateResponse {
    pub ids: Vec<String>,
}

fn check(resp: &gloo::net::http::Response) -> Result<(), String> {
    if !resp.ok() {
        return Err(format!("HTTP {}: {}", resp.status(), resp.status_text()));
    }
    Ok(())
}

pub async fn fetch<T: for<'de> Deserialize<'de>>(path: &str) -> Result<T, String> {
    let resp = Request::get(&format!("{TRAILBASE_URL}{path}"))
        .header("Content-Type", "application/json")
        .send()
        .await
        .map_err(|e| e.to_string())?;
    check(&resp)?;
    resp.json::<T>().await.map_err(|e| e.to_string())
}

pub async fn post<B: Serialize, T: for<'de> Deserialize<'de>>(
    path: &str,
    body: &B,
) -> Result<T, String> {
    let resp = Request::post(&format!("{TRAILBASE_URL}{path}"))
        .header("Content-Type", "application/json")
        .json(body)
        .map_err(|e| e.to_string())?
        .send()
        .await
        .map_err(|e| e.to_string())?;
    check(&resp)?;
    resp.json::<T>().await.map_err(|e| e.to_string())
}

pub async fn patch<B: Serialize>(path: &str, body: &B) -> Result<(), String> {
    let resp = Request::patch(&format!("{TRAILBASE_URL}{path}"))
        .header("Content-Type", "application/json")
        .json(body)
        .map_err(|e| e.to_string())?
        .send()
        .await
        .map_err(|e| e.to_string())?;
    check(&resp)
}

pub async fn delete(path: &str) -> Result<(), String> {
    let resp = Request::delete(&format!("{TRAILBASE_URL}{path}"))
        .header("Content-Type", "application/json")
        .send()
        .await
        .map_err(|e| e.to_string())?;
    check(&resp)
}
