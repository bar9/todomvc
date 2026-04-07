# Create a todo
POST {{base_url}}/api/records/v1/todos
Content-Type: application/json
{
  "title": "Buy milk",
  "completed": 0
}
HTTP 200
[Captures]
todo_id: jsonpath "$.ids[0]"

# Read the created todo
GET {{base_url}}/api/records/v1/todos/{{todo_id}}
HTTP 200
[Asserts]
jsonpath "$.title" == "Buy milk"
jsonpath "$.completed" == 0

# Toggle completed
PATCH {{base_url}}/api/records/v1/todos/{{todo_id}}
Content-Type: application/json
{
  "completed": 1
}
HTTP 200

# Verify completed
GET {{base_url}}/api/records/v1/todos/{{todo_id}}
HTTP 200
[Asserts]
jsonpath "$.completed" == 1

# Update title
PATCH {{base_url}}/api/records/v1/todos/{{todo_id}}
Content-Type: application/json
{
  "title": "Buy oat milk"
}
HTTP 200

# Verify updated title
GET {{base_url}}/api/records/v1/todos/{{todo_id}}
HTTP 200
[Asserts]
jsonpath "$.title" == "Buy oat milk"
jsonpath "$.completed" == 1

# Delete
DELETE {{base_url}}/api/records/v1/todos/{{todo_id}}
HTTP 200

# Verify deleted
GET {{base_url}}/api/records/v1/todos/{{todo_id}}
HTTP 404
