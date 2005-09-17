CREATE TABLE 'widgets' (
  'id'         INTEGER NOT NULL PRIMARY KEY,
  'title'      VARCHAR(50),
  'deleted_at' DATETIME
);

CREATE TABLE 'categories' (
  'id'         INTEGER NOT NULL PRIMARY KEY,
  'widget_id'  INTEGER,
  'title'      VARCHAR(50),
  'deleted_at' DATETIME
);

CREATE TABLE 'categories_widgets' (
  'category_id' INTEGER,
  'widget_id' INTEGER
);
