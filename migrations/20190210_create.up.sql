CREATE TABLE todo
(
  todo_id    INTEGER PRIMARY KEY AUTO_INCREMENT,
  user_id    CHAR(12)     NOT NULL,
  date_added DATETIME DEFAULT NOW(),
  body       VARCHAR(255) NOT NULL,
  INDEX (user_id),
  INDEX (date_added)
);
