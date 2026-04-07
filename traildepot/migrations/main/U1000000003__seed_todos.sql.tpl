-- Seed 200,000 todos for performance testing.
-- Uses a recursive CTE to generate rows efficiently in a single statement.

INSERT INTO todos (title, completed)
WITH RECURSIVE seq(n) AS (
  SELECT 1
  UNION ALL
  SELECT n + 1 FROM seq WHERE n < 200000
)
SELECT
  'Todo item #' || n,
  CASE WHEN n % 5 = 0 THEN 1 ELSE 0 END
FROM seq;
