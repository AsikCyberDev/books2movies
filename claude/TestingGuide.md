# Book to Movie Platform API Testing Guide

## Setup Instructions

1. **Database Setup**
```bash
# Create database
createdb book_to_movie

# Run schema script
psql -d book_to_movie -f schema.sql

# Run functions and data script
psql -d book_to_movie -f functions-and-data.sql
```

2. **Environment Setup**
```bash
# Install dependencies
npm install

# Set up environment variables
cp .env.example .env
# Edit .env with your database credentials
```

3. **Start the Server**
```bash
# Development mode
npm run dev

# Production mode
npm start
```

## Running Tests

### Automated Tests
```bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run specific test file
npm test tests/api.test.js
```

### Manual Testing with Postman

1. Import the provided Postman collection
2. Set up environment variables:
   - `baseUrl`: http://localhost:3000
   - `readerToken`: (obtained after login)
   - `directorToken`: (obtained after login)
   - `adminToken`: (obtained after login)
   - `suggestionId`: (obtained after creating a suggestion)
   - `notificationId`: (obtained from notifications endpoint)

#### Test Flow

1. **Authentication**
   - Register a reader user
   - Register a director user
   - Register an admin user
   - Login with each user and save their tokens

2. **Book Suggestions**
   - Create a new suggestion (as reader)
   - Get all suggestions
   - Get a single suggestion
   - Upvote a suggestion (as director)

3. **Comments**
   - Add a comment to a suggestion
   - Get comments for a suggestion

4. **Search**
   - Search suggestions with different criteria
   - Test full-text search
   - Test genre filtering
   - Test upvote filtering

5. **Admin Functions**
   - Get pending suggestions
   - Update suggestion status
   - Verify permission checks

6. **Notifications**
   - Check for notifications after actions
   - Mark notifications as read
   - Verify notification creation triggers

## Common Test Cases

### Authentication
- [x] Register with valid data
- [x] Register with duplicate email
- [x] Login with correct credentials
- [x] Login with incorrect password
- [x] Access protected routes without token

### Book Suggestions
- [x] Create suggestion with all required fields
- [x] Create suggestion with missing fields
- [x] Get suggestions with various filters
- [x] Upvote suggestion multiple times (should fail)
- [x] Update suggestion by non-owner (should fail)

### Comments
- [x] Add comment to non-existent suggestion
- [x] Get comments with pagination
- [x] Add comment without authentication
- [x] Delete comment by non-owner

### Search
- [x] Search with multiple words
- [x] Search with genre filter
- [x] Search with minimum upvotes
- [x] Search with invalid parameters

### Admin Functions
- [x] Access admin routes as non-admin
- [x] Update suggestion status with invalid status
- [x] Get pending suggestions pagination

### Edge Cases
- [x] Handle large number of simultaneous requests
- [x] Handle malformed JSON in requests
- [x] Test with very long text inputs
- [x] Test with special characters
- [x] Test rate limiting

## Troubleshooting

### Common Issues

1. **Database Connection**
```bash
# Check database connection
psql -d book_to_movie -c "SELECT NOW()"
```

2. **Token Issues**
- Verify token format in Authorization header
- Check token expiration
- Ensure correct role permissions

3. **Query Performance**
```sql
-- Check slow queries
SELECT * FROM pg_stat_activity WHERE state = 'active';
```

### Monitoring

1. **Server Logs**
```bash
# View logs
tail -f logs/app.log
```

2. **Database Monitoring**
```sql
-- Check table sizes
SELECT relname as table_name,
       pg_size_pretty(pg_total_relation_size(relid)) as total_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;
```

## Performance Testing

1. **Load Testing**
```bash
# Using artillery
artillery quick --count 100 -n 50 http://localhost:3000/api/suggestions

# Using ab (Apache Bench)
ab -n 1000 -c 50 http://localhost:3000/api/suggestions
```

2. **Database Performance**
```sql
-- Add test data for performance testing
INSERT INTO book_suggestions (title, author, isbn, pitch, genre, suggested_by)
SELECT 
    'Book ' || generate_series(1,1000),
    'Author ' || generate_series(1,1000),
    '978' || lpad(generate_series(1,1000)::text, 10, '0'),
    'Test pitch ' || generate_series(1,1000),
    ARRAY['thriller', 'mystery'],
    '11111111-1111-1111-1111-111111111111';
```