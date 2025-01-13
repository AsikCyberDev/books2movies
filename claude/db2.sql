-- Function and test data script for Book to Movie Platform

-- Create trigger functions

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Upvote management functions
CREATE OR REPLACE FUNCTION increment_upvote_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE book_suggestions
    SET upvote_count = upvote_count + 1
    WHERE id = NEW.suggestion_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement_upvote_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE book_suggestions
    SET upvote_count = upvote_count - 1
    WHERE id = OLD.suggestion_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Notification creation function
CREATE OR REPLACE FUNCTION create_notification()
RETURNS TRIGGER AS $$
DECLARE
    suggestion_title TEXT;
    suggestion_owner UUID;
BEGIN
    -- Get suggestion title and owner
    SELECT title, suggested_by 
    INTO suggestion_title, suggestion_owner
    FROM book_suggestions 
    WHERE id = NEW.suggestion_id;

    -- Create notification based on action type
    IF TG_TABLE_NAME = 'comments' THEN
        INSERT INTO notifications (user_id, type, message)
        VALUES (suggestion_owner, 'comment', 
                'Someone commented on your suggestion "' || suggestion_title || '"');
    ELSIF TG_TABLE_NAME = 'upvotes' THEN
        INSERT INTO notifications (user_id, type, message)
        VALUES (suggestion_owner, 'upvote', 
                'Your suggestion "' || suggestion_title || '" received a new upvote');
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to handle suggestion status changes
CREATE OR REPLACE FUNCTION handle_suggestion_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status != OLD.status THEN
        INSERT INTO notifications (user_id, type, message)
        VALUES (
            NEW.suggested_by,
            'status_change',
            'Your suggestion "' || NEW.title || '" has been ' || NEW.status
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Utility function to refresh trending genres
CREATE OR REPLACE FUNCTION refresh_trending_genres()
RETURNS TRIGGER AS $$
BEGIN
    REFRESH MATERIALIZED VIEW trending_genres;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Maintenance function to cleanup old notifications
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM notifications
    WHERE read = true
    AND created_at < CURRENT_TIMESTAMP - INTERVAL '90 days'
    RETURNING COUNT(*) INTO deleted_count;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Analytics function for suggestion statistics
CREATE OR REPLACE FUNCTION get_suggestion_stats(suggestion_uuid UUID)
RETURNS TABLE (
    total_upvotes INTEGER,
    total_comments INTEGER,
    unique_commenters INTEGER,
    avg_comment_length NUMERIC,
    days_since_creation INTEGER,
    engagement_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bs.upvote_count as total_upvotes,
        COUNT(DISTINCT c.id) as total_comments,
        COUNT(DISTINCT c.user_id) as unique_commenters,
        AVG(LENGTH(c.content))::NUMERIC as avg_comment_length,
        EXTRACT(DAY FROM (CURRENT_TIMESTAMP - bs.created_at))::INTEGER as days_since_creation,
        (bs.upvote_count + COUNT(DISTINCT c.id))::NUMERIC / 
            GREATEST(EXTRACT(DAY FROM (CURRENT_TIMESTAMP - bs.created_at))::INTEGER, 1) 
            as engagement_rate
    FROM book_suggestions bs
    LEFT JOIN comments c ON bs.id = c.suggestion_id
    WHERE bs.id = suggestion_uuid
    GROUP BY bs.id, bs.upvote_count, bs.created_at;
END;
$$ LANGUAGE plpgsql;

-- Create triggers

-- Update timestamps
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_book_suggestions_updated_at
    BEFORE UPDATE ON book_suggestions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_comments_updated_at
    BEFORE UPDATE ON comments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_original_stories_updated_at
    BEFORE UPDATE ON original_stories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Upvote management
CREATE TRIGGER increment_suggestion_upvotes
    AFTER INSERT ON upvotes
    FOR EACH ROW
    EXECUTE FUNCTION increment_upvote_count();

CREATE TRIGGER decrement_suggestion_upvotes
    AFTER DELETE ON upvotes
    FOR EACH ROW
    EXECUTE FUNCTION decrement_upvote_count();

-- Notification creation
CREATE TRIGGER create_comment_notification
    AFTER INSERT ON comments
    FOR EACH ROW
    EXECUTE FUNCTION create_notification();

CREATE TRIGGER create_upvote_notification
    AFTER INSERT ON upvotes
    FOR EACH ROW
    EXECUTE FUNCTION create_notification();

CREATE TRIGGER handle_suggestion_status
    AFTER UPDATE OF status ON book_suggestions
    FOR EACH ROW
    EXECUTE FUNCTION handle_suggestion_status_change();

-- Trending genres refresh
CREATE TRIGGER refresh_trending_genres_trigger
    AFTER INSERT OR UPDATE OR DELETE ON book_suggestions
    FOR EACH STATEMENT
    EXECUTE FUNCTION refresh_trending_genres();

-- Insert test data

-- Insert test users
-- Note: password_hash would be properly hashed in production. These are just for testing.
INSERT INTO users (id, email, username, password_hash, role, first_name, last_name, bio) VALUES
    ('11111111-1111-1111-1111-111111111111', 'reader1@example.com', 'bookworm', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj2NXFp3dRdu', 'reader', 'John', 'Doe', 'Avid reader and movie enthusiast'),
    ('22222222-2222-2222-2222-222222222222', 'reader2@example.com', 'readinglover', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj2NXFp3dRdu', 'reader', 'Jane', 'Smith', 'Book club organizer'),
    ('33333333-3333-3333-3333-333333333333', 'director1@example.com', 'filmmaker', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj2NXFp3dRdu', 'director', 'Steven', 'Wilson', 'Independent filmmaker with focus on drama'),
    ('44444444-4444-4444-4444-444444444444', 'director2@example.com', 'producer', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj2NXFp3dRdu', 'director', 'Maria', 'Garcia', 'Studio executive interested in YA adaptations'),
    ('55555555-5555-5555-5555-555555555555', 'admin@example.com', 'admin', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj2NXFp3dRdu', 'admin', 'Admin', 'User', 'Platform administrator');

-- Insert test book suggestions
INSERT INTO book_suggestions (id, title, author, isbn, asin, cover_image_url, synopsis, pitch, genre, publication_year, page_count, suggested_by, upvote_count, status) VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'The Silent Echo', 'Elizabeth Matthews', '9781234567890', 'B00EXAMPLE', 'https://example.com/cover1.jpg', 
    'A psychological thriller about a small town haunted by a decades-old mystery.', 
    'This gripping mystery would translate perfectly to screen with its visual atmosphere and intricate plot twists.',
    ARRAY['thriller', 'mystery', 'psychological'],
    2023, 342, '11111111-1111-1111-1111-111111111111', 25, 'approved'),

    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Tomorrow''s Dawn', 'Marcus Chen', '9780987654321', 'B01EXAMPLE', 'https://example.com/cover2.jpg',
    'A near-future sci-fi novel about humanity''s first contact with artificial consciousness.',
    'With the current AI boom, this thoughtful exploration of consciousness would resonate strongly with modern audiences.',
    ARRAY['science fiction', 'artificial intelligence', 'philosophical'],
    2022, 418, '22222222-2222-2222-2222-222222222222', 42, 'featured'),

    ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'The Last Garden', 'Sarah O''Connor', '9785555555555', 'B02EXAMPLE', 'https://example.com/cover3.jpg',
    'A post-apocalyptic tale of hope, following a botanist''s quest to preserve Earth''s plant life.',
    'This environmental thriller combines spectacular visuals with a timely message about climate change.',
    ARRAY['science fiction', 'climate fiction', 'adventure'],
    2023, 289, '11111111-1111-1111-1111-111111111111', 15, 'pending');

-- Insert test upvotes
INSERT INTO upvotes (user_id, suggestion_id) VALUES
    ('11111111-1111-1111-1111-111111111111', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
    ('22222222-2222-2222-2222-222222222222', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
    ('33333333-3333-3333-3333-333333333333', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
    ('44444444-4444-4444-4444-444444444444', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
    ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

-- Insert test comments
INSERT INTO comments (id, content, user_id, suggestion_id) VALUES
    ('11111111-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'This would make an amazing psychological thriller. The atmosphere is perfect for film.', 
    '33333333-3333-3333-3333-333333333333', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
    
    ('22222222-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'The character development in this book is exceptional. Would love to see it adapted.',
    '44444444-4444-4444-4444-444444444444', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
    
    ('33333333-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'The AI concepts in this book are groundbreaking. Perfect timing for a film adaptation.',
    '33333333-3333-3333-3333-333333333333', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');

-- Sample test queries

-- Full-text search for suggestions
SELECT title, author, ts_rank_cd(search_vector, query) AS rank
FROM book_suggestions, plainto_tsquery('english', 'artificial intelligence future') query
WHERE search_vector @@ query
ORDER BY rank DESC;

-- Get trending genres
SELECT *
FROM trending_genres
WHERE suggestion_count >= 2
ORDER BY total_upvotes DESC;

-- Get user reputation with engagement metrics
SELECT 
    u.username,
    ur.reputation_score,
    ur.suggestions_made,
    ur.total_suggestion_upvotes,
    ur.comments_made,
    ur.upvotes_given
FROM user_reputation ur
JOIN users u ON ur.id = u.id
ORDER BY ur.reputation_score DESC;

-- Get suggestion statistics for a specific book
SELECT 
    bs.title,
    u.username as suggested_by,
    stats.*
FROM book_suggestions bs
JOIN users u ON bs.suggested_by = u.id
CROSS JOIN LATERAL get_suggestion_stats(bs.id) stats
WHERE bs.id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

-- Refresh materialized views
REFRESH MATERIALIZED VIEW trending_genres;

COMMIT;