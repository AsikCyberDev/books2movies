-- Create the database (if it doesn't exist)
-- CREATE DATABASE book_to_movie_db;

-- Use the database (if you're not already connected to it)
-- \c book_to_movie_db

-- ---
-- Table: users
-- ---

DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL, -- Store hashed passwords in production
    role VARCHAR(50) NOT NULL CHECK (role IN ('Reader', 'Director', 'Admin')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ---
-- Table: book_suggestions
-- ---

DROP TABLE IF EXISTS book_suggestions CASCADE;

CREATE TABLE book_suggestions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(255) NOT NULL,
    isbn VARCHAR(20),
    cover_image_url TEXT,
    synopsis TEXT,
    pitch TEXT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ---
-- Table: upvotes
-- ---

DROP TABLE IF EXISTS upvotes CASCADE;

CREATE TABLE upvotes (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    suggestion_id INTEGER REFERENCES book_suggestions(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, suggestion_id) -- Ensure a user can only upvote a suggestion once
);

-- ---
-- Table: comments
-- ---

DROP TABLE IF EXISTS comments CASCADE;

CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    suggestion_id INTEGER REFERENCES book_suggestions(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ---
-- Table: original_stories (Optional)
-- ---

DROP TABLE IF EXISTS original_stories CASCADE;

CREATE TABLE original_stories (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    genre VARCHAR(255) NOT NULL,
    logline TEXT NOT NULL,
    synopsis TEXT NOT NULL,
    full_text TEXT, -- Consider storing large text in a separate table or using cloud storage
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ---
-- Table: notifications
-- ---
DROP TABLE IF EXISTS notifications CASCADE;

CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('comment', 'upvote', 'admin_action')),
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    related_item_id INTEGER, -- Can relate to book_suggestions, original_stories, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ---
-- Insert Dummy Data
-- ---

-- Users
INSERT INTO users (email, password, role) VALUES
('reader1@example.com', 'password123', 'Reader'),
('reader2@example.com', 'password123', 'Reader'),
('reader3@example.com', 'password123', 'Reader'),
('director1@example.com', 'password123', 'Director'),
('director2@example.com', 'password123', 'Director'),
('admin@example.com', 'adminpass', 'Admin');

-- Book Suggestions
INSERT INTO book_suggestions (user_id, title, author, isbn, cover_image_url, synopsis, pitch, status) VALUES
(1, 'The Hitchhiker''s Guide to the Galaxy', 'Douglas Adams', '978-0345391803', 'https://example.com/hitchhikers_cover.jpg', 'Seconds before the Earth is demolished...', 'A hilarious and insightful sci-fi comedy that would make a fantastic movie!', 'approved'),
(1, 'Pride and Prejudice', 'Jane Austen', '978-0141439518', 'https://example.com/pride_prejudice_cover.jpg', 'Sparks fly when spirited Elizabeth Bennet meets single, rich, and proud Mr. Darcy.', 'A timeless classic with witty dialogue and engaging characters, perfect for a period drama adaptation.', 'approved'),
(2, 'The Lord of the Rings', 'J.R.R. Tolkien', '978-0618640157', 'https://example.com/lotr_cover.jpg', 'A meek hobbit and his companions set out on a journey to destroy the One Ring.', 'This epic fantasy has already been adapted, but a new take with modern technology could be amazing!', 'pending'),
(3, 'To Kill a Mockingbird', 'Harper Lee', '978-0446310789', 'https://example.com/mockingbird_cover.jpg', 'A gripping story about racial injustice and childhood innocence in the American South.', 'A powerful and moving story that deserves a fresh cinematic interpretation.', 'approved'),
(4, 'Dune', 'Frank Herbert', '978-0441172719', 'https://example.com/dune_cover.jpg', 'Set on the desert planet Arrakis, the story follows young Paul Atreides...', 'A visually stunning and thought-provoking sci-fi epic that would be incredible on the big screen.', 'approved'),
(5, '1984', 'George Orwell', '978-0451524935', 'https://example.com/1984_cover.jpg', 'A dystopian novel about a totalitarian regime and one man''s rebellion.', 'A chilling and relevant story that could be adapted into a thought-provoking thriller.', 'pending');

-- Upvotes
INSERT INTO upvotes (user_id, suggestion_id) VALUES
(1, 1),
(2, 1),
(3, 1),
(4, 1),
(5, 1),
(1, 2),
(2, 2),
(3, 2),
(4, 4),
(5, 4),
(1, 5),
(2, 5),
(3, 5),
(4, 5),
(5, 5);

-- Comments
INSERT INTO comments (user_id, suggestion_id, text) VALUES
(2, 1, 'I completely agree! The humor in this book is fantastic.'),
(4, 1, 'This would be a great project for a visionary director.'),
(1, 2, 'A new adaptation could really bring out the social commentary in the novel.'),
(5, 2, 'I''d love to see the Bennet sisters on screen again!'),
(3, 4, 'This book''s message is more important now than ever.'),
(1, 5, 'The world of Dune is so rich and complex, it would be amazing to see it fully realized in a movie.'),
(5, 5, 'I agree. This would require a huge budget but it would be worth it!');

-- Original Stories (Optional)
INSERT INTO original_stories (user_id, title, genre, logline, synopsis, full_text) VALUES
(3, 'The Last Starlight', 'Science Fiction', 'A lone astronaut must choose between saving humanity or embracing oblivion in a dying universe.', 'In a far future where stars are fading, an astronaut on a desperate mission discovers a hidden truth that could change everything.', 'Chapter 1: The Void\n...'),
(4, 'Echoes of the Past', 'Mystery', 'A detective haunted by a cold case finds a new clue that could unravel a decades-old conspiracy.', 'Detective Miles Corbin is pulled back into the case that destroyed his career when a mysterious artifact is discovered...', 'Chapter 1: The Relic\n...');

-- Notifications
INSERT INTO notifications (user_id, type, message, related_item_id) VALUES
(1, 'comment', 'director1@example.com commented on your suggestion for The Hitchhiker''s Guide to the Galaxy.', 1),
(1, 'upvote', 'reader2@example.com upvoted your suggestion for The Hitchhiker''s Guide to the Galaxy.', 1),
(1, 'upvote', 'reader3@example.com upvoted your suggestion for The Hitchhiker''s Guide to the Galaxy.', 1),
(1, 'upvote', 'director1@example.com upvoted your suggestion for The Hitchhiker''s Guide to the Galaxy.', 1),
(1, 'upvote', 'director2@example.com upvoted your suggestion for The Hitchhiker''s Guide to the Galaxy.', 1),
(1, 'comment', 'director2@example.com commented on your suggestion for Pride and Prejudice.', 2),
(3, 'comment', 'reader1@example.com commented on your suggestion for To Kill a Mockingbird.', 4);

-- ---
-- Function to update updated_at column
-- ---

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ---
-- Triggers to update updated_at on modification
-- ---

CREATE TRIGGER update_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_book_suggestions_updated_at
BEFORE UPDATE ON book_suggestions
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_original_stories_updated_at
BEFORE UPDATE ON original_stories
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();