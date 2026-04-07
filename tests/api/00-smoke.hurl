# Health check
GET {{base_url}}/api/healthcheck
HTTP 200

# List todos
GET {{base_url}}/api/records/v1/todos?order=created
HTTP 200
[Asserts]
jsonpath "$.records" isCollection
