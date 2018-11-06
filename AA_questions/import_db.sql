PRAGMA foreign_keys = ON;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  author_id INTEGER NOT NULL,
  FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE question_follows (
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  body TEXT NOT NULL,
  question_id INTEGER NOT NULL,
  parent_reply_id INTEGER,
  user_id INTEGER NOT NULL,
  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (parent_reply_id) REFERENCES replies(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_likes (
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO
  users (fname, lname)
VALUES 
  ("Ben", "Cowden"),
  ("George", "Wang");
  
INSERT INTO 
  questions (title, body, author_id)
VALUES 
  ("Question 1", "This is the question?", (SELECT id FROM users WHERE fname = 'Ben' AND lname = 'Cowden')),
  ("Question 2", "Why is the sky blue?", (SELECT id FROM users WHERE fname = 'George' AND lname = 'Wang')),
  ("Question 3", "Is aA better than Hack Reactor?", (SELECT id FROM users WHERE fname = 'George' AND lname = 'Wang'));
  
INSERT INTO 
  question_follows (user_id, question_id) 
VALUES 
  (1,1),
  (1,3),
  (2,1),
  (2,2),
  (2,3);

INSERT INTO 
  replies (body, question_id, parent_reply_id, user_id)
VALUES 
  ("Cause that is the way it is.", 1, NULL, 2),
  ("That does not answer my question.", 1, 1, 1),
  ("Thanks, that totally answers my question.", 1, 1, 1),
  ("Obviously yes, you fool.", 3, NULL, 1);
  
INSERT INTO
  question_likes (user_id, question_id)
VALUES
  (1,3),
  (2,1),
  (2,2);