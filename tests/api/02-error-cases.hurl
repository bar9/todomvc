# Missing required field (no title)
POST {{base_url}}/api/records/v1/todos
Content-Type: application/json
{
  "completed": 0
}
HTTP 400

# Empty body
POST {{base_url}}/api/records/v1/todos
Content-Type: application/json
{}
HTTP 400

# PATCH non-existent todo (TrailBase returns 500 for missing records with world ACL)
PATCH {{base_url}}/api/records/v1/todos/00000000-0000-0000-0000-000000000000
Content-Type: application/json
{
  "title": "ghost"
}
HTTP 500

# DELETE non-existent todo
DELETE {{base_url}}/api/records/v1/todos/00000000-0000-0000-0000-000000000000
HTTP 404
