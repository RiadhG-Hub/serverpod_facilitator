-- Create table user
CREATE TABLE user (
  id TEXT PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  name TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL
);


