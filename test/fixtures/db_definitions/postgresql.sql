CREATE TABLE widgets (
  id         SERIAL,
  title      VARCHAR(50),
  deleted_at TIMESTAMP
);
SELECT setval('widgets_id_seq', 100);

CREATE TABLE categories (
  id         SERIAL,
  widget_id  INT,
  title      VARCHAR(50),
  deleted_at TIMESTAMP
);
SELECT setval('categories_id_seq', 100);

CREATE TABLE categories_widgets (
  category_id INT,
  widget_id   INT
);