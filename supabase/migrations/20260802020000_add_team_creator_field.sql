-- 添加团队创建者标识字段
-- 只有团队创建者（第一个加入团队的 remote）可以设置汇率公式

-- 添加 is_team_creator 字段到 users 表
ALTER TABLE users ADD COLUMN is_team_creator BOOLEAN DEFAULT FALSE;

-- 为每个团队的第一个用户设置为创建者
-- 假设创建时间最早的用户是团队创建者
WITH first_users AS (
  SELECT DISTINCT ON (team_id) id, team_id
  FROM users
  WHERE team_id IS NOT NULL
  ORDER BY team_id, created_at ASC
)
UPDATE users
SET is_team_creator = TRUE
WHERE id IN (SELECT id FROM first_users);

-- 添加注释
COMMENT ON COLUMN users.is_team_creator IS 'Whether this user is the team creator (first member), only team creators can modify exchange formulas';
