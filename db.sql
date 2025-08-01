#CREATE USER 'test'@'localhost' IDENTIFIED BY 'test'; 
#GRANT ALL PRIVILEGES ON task_manager.* to 'test'@'localhost'; 

FLUSH PRIVILEGES;
SHOW DATABASES;
SELECT CURRENT_USER();

USE task_manager;
SELECT DATABASE();

CREATE TABLE priorities (
id INT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(20) NOT NULL UNIQUE, #low, med, high
sort_order INT NOT NULL, #sorting by importance
created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO priorities (name, sort_order) VALUES
('LOW', 1), ('MEDIUM', 2), ('HIGH', 3), ('BLOCKER', 4);

CREATE TABLE tags (
id INT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(50) NOT NULL UNIQUE,
created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP);
INSERT INTO tags (name) VALUES
('backend'),('frontend'),('urgent'),('doc');

CREATE TABLE project_roles(
id INT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(30) NOT NULL UNIQUE,
created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO project_roles (name) VALUES
('OWNER'), ('MAINTAINER'), ('VIEWER');

SHOW TABLES;
SELECT * FROM priorities;
SELECT * FROM tags;
SELECT * FROM  project_roles;

CREATE TABLE users (
id INT AUTO_INCREMENT PRIMARY KEY,
full_name VARCHAR(100) NOT NULL,
email VARCHAR(120) UNIQUE,
created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP );

INSERT INTO users (full_name, email) VALUES
('John Smith', 'john@email.com'),
('Jane Doe', 'jane@email.com'),
('Patrick Star', 'patrick@email.com');

SELECT * FROM users;
DESCRIBE users;

CREATE TABLE projects (
id INT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(120) NOT NULL UNIQUE,
description TEXT,
created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO projects (name, description) VALUES
('Internal Tools', 'Dashboard'), ('Marketing', 'Website');

SELECT * FROM projects;
DESCRIBE projects;

SHOW TABLES;
SELECT COUNT(*) AS users_count FROM users;
SELECT COUNT(*) AS projects_count FROM projects;

CREATE TABLE project_memberships (
id INT AUTO_INCREMENT PRIMARY KEY,
project_id INT NOT NULL,
user_id INT NOT NULL,
role_id INT NOT NULL,
added_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
CONSTRAINT fk_pm_project FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
CONSTRAINT fk_pm_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
CONSTRAINT fk_pm_role FOREIGN KEY (role_id) REFERENCES project_roles(id) ON DELETE RESTRICT,
CONSTRAINT uq_pm UNIQUE (project_id, user_id)
);

CREATE INDEX idx_pm_project ON project_memberships(project_id);
CREATE INDEX indx_pm_user ON project_memberships(user_id);

DESCRIBE project_memberships;

INSERT INTO project_memberships (project_id, user_id, role_id)
SELECT p.id, u.id, r.id
FROM projects p, users u, project_roles r
WHERE p.name = 'Marketing' and u.full_name = 'John Smith' AND r.name = 'OWNER';

INSERT INTO project_memberships (project_id, user_id, role_id)
SELECT p.id, u.id, r.id
FROM projects p, users u, project_roles r
WHERE p.name = 'Marketing' and u.full_name = 'Jane Doe' AND r.name = 'MAINTAINER';

INSERT INTO project_memberships (project_id, user_id, role_id)
SELECT p.id, u.id, r.id
FROM projects p, users u, project_roles r
WHERE p.name = 'Internal Tools' and u.full_name = 'Patrick Star' AND r.name = 'OWNER';

INSERT INTO project_memberships (project_id, user_id, role_id)
SELECT p.id, u.id, r.id
FROM projects p, users u, project_roles r
WHERE p.name = 'Internal Tools' and u.full_name = 'John Smith' AND r.name = 'VIEWER';

SELECT p.name AS project,
	u.full_name AS Member,
    r.name AS role_name,
    pm.added_at
FROM project_memberships pm
JOIN projects p ON p.id = pm.project_id
JOIN users u ON u.id = pm.user_id
JOIN project_roles r ON r.id = pm.role_id
ORDER BY p.name, role_name, member;

CREATE TABLE tasks (
id INT AUTO_INCREMENT PRIMARY KEY,
project_id INT NOT NULL,
title VARCHAR(150) NOT NULL,
description TEXT,
assigned_to INT NULL,
priority_id INT NOT NULL,
status VARCHAR(20) NOT NULL DEFAULT 'TO_DO',
due_date DATE NULL,

created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

CONSTRAINT fk_task_project   FOREIGN KEY (project_id)  REFERENCES projects(id)   ON DELETE CASCADE,
  CONSTRAINT fk_task_assignee  FOREIGN KEY (assigned_to) REFERENCES users(id)      ON DELETE SET NULL,
  CONSTRAINT fk_task_priority  FOREIGN KEY (priority_id) REFERENCES priorities(id) ON DELETE RESTRICT,
  CONSTRAINT chk_task_status CHECK (status IN ('TO_DO','IN_PROGRESS','BLOCKED','DONE')));
  
CREATE INDEX idx_task_project ON tasks(project_id);
CREATE INDEX idx_task_assigned_to ON tasks(assigned_to);
CREATE INDEX idx_task_priority ON tasks(priority_id);
CREATE INDEX idx_task_status_due ON tasks(status, due_date);

DESCRIBE tasks;
SHOW CREATE TABLE tasks;

INSERT INTO tasks (project_id, title, assigned_to, priority_id, status, due_date)
VALUES (
  (SELECT id FROM projects WHERE name='Marketing'),
  'Create home page',
  (SELECT id FROM users WHERE full_name='John Smith'),
  (SELECT id FROM priorities WHERE name='HIGH'),
  'IN_PROGRESS',
  DATE_ADD(CURDATE(), INTERVAL 3 DAY)
);

INSERT INTO tasks (project_id, title, assigned_to, priority_id, status, due_date)
VALUES (
  (SELECT id FROM projects WHERE name='Marketing'),
  'Develop front end style and implement',
  NULL,
  (SELECT id FROM priorities WHERE name='MEDIUM'),
  'TO_DO',
  DATE_ADD(CURDATE(), INTERVAL 7 DAY)
);

INSERT IGNORE INTO priorities (name, sort_order) VALUES ('BLOCKER', 4);

INSERT INTO tasks (project_id, title, assigned_to, priority_id, status, due_date)
VALUES (
  (SELECT id FROM projects WHERE name='Internal Tools'),
  'Create customer database',
  NULL,
  (SELECT id FROM priorities WHERE name='BLOCKER'),
  'BLOCKED',
  DATE_ADD(CURDATE(), INTERVAL -1 DAY)
);

SELECT
t.id,
t.title,
COALESCE (u.full_name, '(unassigned)') AS assignee,
p.name AS priority,
t.status,
t.due_date
FROM tasks t
LEFT JOIN users u ON u.id = t.assigned_to
JOIN priorities p ON p.id = t.priority_id
WHERE t.project_id = (SELECT id FROM projects WHERE name = 'Marketing')
ORDER BY
FIELD (t.status, 'BLOCKED', 'IN_PROGRESS', 'TO_DO', 'DONE'),
t.due_date;

CREATE TABLE task_tags (
  task_id INT NOT NULL,
  tag_id  INT NOT NULL,
  PRIMARY KEY (task_id, tag_id),   

  CONSTRAINT fk_tt_task FOREIGN KEY (task_id)
    REFERENCES tasks(id) ON DELETE CASCADE,

  CONSTRAINT fk_tt_tag FOREIGN KEY (tag_id)
    REFERENCES tags(id) ON DELETE CASCADE
);
CREATE INDEX idx_tt_tag ON task_tags(tag_id);

INSERT INTO task_tags (task_id, tag_id)
SELECT t.id, g.id
FROM tasks t, tags g
WHERE t.title='Create home page' AND g.name='frontend';

INSERT INTO task_tags (task_id, tag_id)
SELECT t.id, g.id
FROM tasks t, tags g
WHERE t.title='Create home page' AND g.name='urgent';

SELECT pr.name AS project,
       t.title AS task,
       GROUP_CONCAT(g.name) AS tags
FROM task_tags tt
JOIN tasks t     ON t.id = tt.task_id
JOIN tags g      ON g.id = tt.tag_id
JOIN projects pr ON pr.id = t.project_id
GROUP BY pr.name, t.title;

INSERT IGNORE INTO priorities (name, sort_order) VALUES ('BLOCKER', 4);

CREATE TABLE comments (
id INT AUTO_INCREMENT PRIMARY KEY,
task_id INT NOT NULL,
author_user_id INT NOT NULL,
body TEXT NOT NULL,
created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

CONSTRAINT fk_comment_task FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
CONSTRAINT fk_comment_user FOREIGN KEY (author_user_id) REFERENCES users(id) ON DELETE CASCADE);

CREATE INDEX idx_comment_task_created ON comments(task_id, created_at DESC);

INSERT INTO comments (task_id, author_user_id, body)
SELECT t.id, u.id, 'Initial plan made.'
from tasks t, users u
WHERE t.title = 'Create home page' AND u.full_name = 'John Smith';
INSERT INTO comments (task_id, author_user_id, body)
SELECT t.id, u.id, 'Start date: tomorrow'
FROM tasks t, users u
WHERE t.title = 'Create home page' AND u.full_name = 'Jane Doe';

CREATE TABLE status_history (
id INT AUTO_INCREMENT PRIMARY KEY,
task_id INT NOT NULL,
changed_by INT NULL,
old_status VARCHAR(20),
new_status VARCHAR(20) NOT NULL,
changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
CONSTRAINT fk_sh_task FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
  CONSTRAINT fk_sh_user FOREIGN KEY (changed_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT chk_sh_vals CHECK (new_status IN ('TO_DO','IN_PROGRESS','BLOCKED','DONE')),
  CONSTRAINT chk_sh_diff CHECK (old_status IS NULL OR old_status <> new_status)
);

CREATE INDEX idx_sh_task_changed ON status_history(task_id, changed_at);

INSERT INTO status_history (task_id, changed_by, old_status, new_status)
SELECT t.id, u.id, NULL, 'TO_DO'
FROM tasks t, users u
WHERE t.title = 'Create home page' AND u.full_name = 'John Smith';

INSERT INTO status_history (task_id, changed_by, old_status, new_status)
SELECT t.id, u.id, 'TO_DO', 'IN_PROGRESS'
FROM tasks t, users u
WHERE t.title = 'Create home page' AND u.full_name = 'Jane Doe';

CREATE TABLE hours_logged (
id INT AUTO_INCREMENT PRIMARY KEY,
task_id INT NOT NULL,
user_id INT NOT NULL,
hours DECIMAL(5,2) NOT NULL,
worked_at DATE NOT NULL,
created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
CONSTRAINT fk_hl_task FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
  CONSTRAINT fk_hl_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
  CONSTRAINT chk_hours CHECK (hours > 0 AND hours <= 24)
);

CREATE INDEX idx_hl_task_worked_at ON hours_logged(task_id, worked_at);
CREATE INDEX idx_hl_user_worked_at ON hours_logged(user_id, worked_at);

INSERT INTO hours_logged (task_id, user_id, hours, worked_at)
SELECT t.id, u.id, 3.5, CURDATE()
from tasks t, users u
WHERE t.title = 'Create home page' AND u.full_name = 'John Smith';

INSERT INTO hours_logged (task_id, user_id, hours, worked_at)
SELECT t.id, u.id, 2.0, CURDATE()
FROM tasks t, users u
WHERE t.title = 'Create customer database' AND u.full_name = 'Patrick Star';

SELECT t.title, u.full_name AS author, c.body, c.created_at
FROM comments c
JOIN tasks t ON t.id = c.task_id
JOIN users u ON u.id = c.author_user_id
ORDER BY t.title, c.created_at;

#following is block of verifications v

SELECT DATABASE() AS current_db, NOW() AS server_time;

SELECT
  (SELECT COUNT(*) FROM priorities)          AS priorities_cnt,
  (SELECT COUNT(*) FROM tags)                AS tags_cnt,
  (SELECT COUNT(*) FROM project_roles)       AS project_roles_cnt,
  (SELECT COUNT(*) FROM users)               AS users_cnt,
  (SELECT COUNT(*) FROM projects)            AS projects_cnt,
  (SELECT COUNT(*) FROM project_memberships) AS project_memberships_cnt,
  (SELECT COUNT(*) FROM tasks)               AS tasks_cnt,
  (SELECT COUNT(*) FROM task_tags)           AS task_tags_cnt,
  (SELECT COUNT(*) FROM comments)            AS comments_cnt,
  (SELECT COUNT(*) FROM status_history)      AS status_history_cnt,
  (SELECT COUNT(*) FROM hours_logged)        AS hours_logged_cnt;

SELECT id, name, sort_order FROM priorities ORDER BY sort_order;
SELECT id, name FROM tags ORDER BY name;
SELECT id, name FROM project_roles ORDER BY name;

SELECT id, full_name, email FROM users ORDER BY id;
SELECT id, name, description FROM projects ORDER BY id;

SELECT p.name AS project, u.full_name AS member, r.name AS role_name, pm.added_at
FROM project_memberships pm
JOIN projects p ON p.id = pm.project_id
JOIN users u    ON u.id = pm.user_id
JOIN project_roles r ON r.id = pm.role_id
ORDER BY p.name, role_name, member;

SELECT
  t.id, t.title,
  COALESCE(u.full_name,'(unassigned)') AS assignee,
  p.name AS priority, t.status, t.due_date
FROM tasks t
JOIN projects pr  ON pr.id = t.project_id
LEFT JOIN users u ON u.id = t.assigned_to
JOIN priorities p ON p.id = t.priority_id
WHERE pr.name = 'Marketing'
ORDER BY FIELD(t.status,'BLOCKED','IN_PROGRESS','TO_DO','DONE'), t.due_date;

SELECT
  t.id, t.title,
  COALESCE(u.full_name,'(unassigned)') AS assignee,
  p.name AS priority, t.status, t.due_date
FROM tasks t
JOIN projects pr  ON pr.id = t.project_id
LEFT JOIN users u ON u.id = t.assigned_to
JOIN priorities p ON p.id = t.priority_id
WHERE pr.name = 'Internal Tools'
ORDER BY FIELD(t.status,'BLOCKED','IN_PROGRESS','TO_DO','DONE'), t.due_date;

SELECT pr.name AS project,
       t.title AS task,
       GROUP_CONCAT(g.name ORDER BY g.name) AS tags
FROM task_tags tt
JOIN tasks t     ON t.id = tt.task_id
JOIN tags g      ON g.id = tt.tag_id
JOIN projects pr ON pr.id = t.project_id
GROUP BY pr.name, t.title
ORDER BY pr.name, t.title;

SELECT t.title, u.full_name AS author, c.body, c.created_at
FROM comments c
JOIN tasks t ON t.id = c.task_id
JOIN users u ON u.id = c.author_user_id
ORDER BY t.title, c.created_at;

SELECT t.title,
       t.status AS current_status,
       sh.new_status AS last_history_status,
       sh.changed_at AS last_change_at
FROM tasks t
JOIN status_history sh ON sh.task_id = t.id
WHERE sh.changed_at = (
  SELECT MAX(ch.changed_at) FROM status_history ch WHERE ch.task_id = t.id
)
ORDER BY t.title;

SELECT p.name AS project, u.full_name, SUM(h.hours) AS total_hours
FROM hours_logged h
JOIN tasks t ON t.id = h.task_id
JOIN projects p ON p.id = t.project_id
JOIN users u ON u.id = h.user_id
GROUP BY p.name, u.full_name
ORDER BY p.name, total_hours DESC;

SELECT t.title, u.full_name, h.hours, h.worked_at, h.created_at
FROM hours_logged h
JOIN tasks t ON t.id = h.task_id
JOIN users u ON u.id = h.user_id
ORDER BY t.title, h.worked_at DESC, h.created_at DESC;

SELECT t.id, t.title FROM tasks t
LEFT JOIN projects p ON p.id = t.project_id
WHERE p.id IS NULL;

SELECT tt.task_id FROM task_tags tt
LEFT JOIN tasks t ON t.id = tt.task_id
WHERE t.id IS NULL;

SELECT c.id FROM comments c
LEFT JOIN tasks t ON t.id = c.task_id
WHERE t.id IS NULL;

SELECT sh.id FROM status_history sh
LEFT JOIN tasks t ON t.id = sh.task_id
WHERE t.id IS NULL;

SELECT h.id FROM hours_logged h
LEFT JOIN tasks t ON t.id = h.task_id
WHERE t.id IS NULL;

EXPLAIN
SELECT pr.name AS project, t.title, p.name AS priority, t.due_date
FROM tasks t
JOIN projects pr ON pr.id = t.project_id
JOIN priorities p ON p.id = t.priority_id
WHERE t.status <> 'DONE' AND t.due_date IS NOT NULL AND t.due_date < CURDATE()
ORDER BY p.sort_order DESC, t.due_date ASC;

#this entire block is verifications ^