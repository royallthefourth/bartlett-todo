CREATE TABLE todo (
  todo_id INTEGER PRIMARY KEY AUTO_INCREMENT,
  user_id CHAR(12) NOT NULL,
  date_added DATETIME DEFAULT NOW(),
  body TEXT NOT NULL,
  INDEX (date_added)
);
