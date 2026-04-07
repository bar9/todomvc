mod api;
mod types;

use dioxus::prelude::*;
use types::{NewTodo, Todo, UpdateTodo};

fn main() {
    wasm_logger::init(wasm_logger::Config::default());
    dioxus::launch(App);
}

#[derive(Clone, Copy, PartialEq)]
enum Filter {
    All,
    Active,
    Completed,
}

#[component]
fn App() -> Element {
    let mut todos: Signal<Vec<Todo>> = use_signal(Vec::new);
    let mut filter = use_signal(|| Filter::All);
    let mut new_title = use_signal(String::new);
    let mut error: Signal<Option<String>> = use_signal(|| None);
    let mut refresh = use_signal(|| 0u32);

    // Load todos (re-runs when refresh changes)
    let _loader = use_resource(move || async move {
        let _ = refresh();
        match api::fetch::<api::ListResponse<Todo>>("/api/records/v1/todos?order=created").await {
            Ok(resp) => {
                todos.set(resp.records);
                error.set(None);
            }
            Err(e) => error.set(Some(e)),
        }
    });

    // Add todo
    let on_add = move |evt: Event<FormData>| {
        evt.prevent_default();
        let title = new_title().trim().to_string();
        if title.is_empty() {
            return;
        }
        new_title.set(String::new());
        spawn(async move {
            let body = NewTodo { title, completed: 0 };
            match api::post::<_, api::CreateResponse>("/api/records/v1/todos", &body).await {
                Ok(_) => refresh += 1,
                Err(e) => error.set(Some(e)),
            }
        });
    };

    // Toggle completed
    let on_toggle = move |todo: Todo| {
        let new_val = if todo.completed == 0 { 1 } else { 0 };
        let id = todo.id.clone().unwrap_or_default();
        spawn(async move {
            let body = UpdateTodo { title: None, completed: Some(new_val) };
            match api::patch(&format!("/api/records/v1/todos/{id}"), &body).await {
                Ok(_) => refresh += 1,
                Err(e) => error.set(Some(e)),
            }
        });
    };

    // Delete single todo
    let on_delete = move |id: String| {
        spawn(async move {
            match api::delete(&format!("/api/records/v1/todos/{id}")).await {
                Ok(_) => refresh += 1,
                Err(e) => error.set(Some(e)),
            }
        });
    };

    // Clear completed
    let on_clear_completed = move |_| {
        let completed_ids: Vec<String> = todos()
            .iter()
            .filter(|t| t.completed != 0)
            .filter_map(|t| t.id.clone())
            .collect();
        spawn(async move {
            for id in completed_ids {
                let _ = api::delete(&format!("/api/records/v1/todos/{id}")).await;
            }
            refresh += 1;
        });
    };

    // Derived counts
    let active_count = todos().iter().filter(|t| t.completed == 0).count();
    let completed_count = todos().iter().filter(|t| t.completed != 0).count();

    // Filtered list
    let visible: Vec<Todo> = todos()
        .iter()
        .filter(|t| match filter() {
            Filter::All => true,
            Filter::Active => t.completed == 0,
            Filter::Completed => t.completed != 0,
        })
        .cloned()
        .collect();

    rsx! {
        document::Stylesheet { href: asset!("/assets/main.css") }

        div { class: "min-h-screen bg-base-200 flex items-start justify-center pt-12",
            div { class: "card bg-base-100 shadow-xl w-full max-w-lg",
                div { class: "card-body",
                    h1 { class: "text-3xl font-bold text-center mb-4 opacity-30", "todos" }

                    // Error banner
                    if let Some(err) = error() {
                        div { class: "alert alert-error mb-4",
                            span { "{err}" }
                            button {
                                class: "btn btn-ghost btn-xs",
                                onclick: move |_| error.set(None),
                                "x"
                            }
                        }
                    }

                    // Input form
                    form { onsubmit: on_add,
                        div { class: "join w-full mb-4",
                            input {
                                class: "input input-bordered join-item flex-1",
                                r#type: "text",
                                placeholder: "What needs to be done?",
                                value: "{new_title}",
                                oninput: move |evt| new_title.set(evt.value()),
                            }
                            button {
                                class: "btn btn-primary join-item",
                                r#type: "submit",
                                "Add"
                            }
                        }
                    }

                    // Todo list
                    ul { class: "space-y-1",
                        for todo in visible.iter() {
                            li { key: "{todo.id.as_deref().unwrap_or_default()}",
                                class: "flex items-center gap-2 p-2 rounded hover:bg-base-200",

                                input {
                                    r#type: "checkbox",
                                    class: "checkbox checkbox-sm",
                                    checked: todo.completed != 0,
                                    onchange: {
                                        let todo = todo.clone();
                                        move |_| on_toggle(todo.clone())
                                    },
                                }

                                span {
                                    class: if todo.completed != 0 { "flex-1 line-through opacity-50" } else { "flex-1" },
                                    "{todo.title}"
                                }

                                button {
                                    class: "btn btn-ghost btn-xs text-error",
                                    onclick: {
                                        let id = todo.id.clone().unwrap_or_default();
                                        move |_| on_delete(id.clone())
                                    },
                                    "x"
                                }
                            }
                        }
                    }

                    // Footer: count + filters + clear
                    if !todos().is_empty() {
                        div { class: "flex items-center justify-between mt-4 text-sm",
                            span { "{active_count} item(s) left" }

                            div { class: "join",
                                button {
                                    class: if filter() == Filter::All { "btn btn-xs join-item btn-active" } else { "btn btn-xs join-item" },
                                    onclick: move |_| filter.set(Filter::All),
                                    "All"
                                }
                                button {
                                    class: if filter() == Filter::Active { "btn btn-xs join-item btn-active" } else { "btn btn-xs join-item" },
                                    onclick: move |_| filter.set(Filter::Active),
                                    "Active"
                                }
                                button {
                                    class: if filter() == Filter::Completed { "btn btn-xs join-item btn-active" } else { "btn btn-xs join-item" },
                                    onclick: move |_| filter.set(Filter::Completed),
                                    "Completed"
                                }
                            }

                            if completed_count > 0 {
                                button {
                                    class: "btn btn-xs btn-ghost",
                                    onclick: on_clear_completed,
                                    "Clear completed"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
