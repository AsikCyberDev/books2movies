// tests/api.test.js
const request = require('supertest');
const app = require('../src/app');
const db = require('../src/config/db');

let readerToken;
let directorToken;
let adminToken;
let suggestionId;

beforeAll(async () => {
  // Clean up test data
  await db.query('DELETE FROM notifications');
  await db.query('DELETE FROM comments');
  await db.query('DELETE FROM upvotes');
  await db.query('DELETE FROM book_suggestions');
  await db.query('DELETE FROM users');
});

describe('Authentication', () => {
  test('Should register a new reader', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'reader@test.com',
        password: 'password123',
        username: 'testReader',
        role: 'reader'
      });
    
    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('token');
    readerToken = res.body.token;
  });

  test('Should register a director', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'director@test.com',
        password: 'password123',
        username: 'testDirector',
        role: 'director'
      });
    
    expect(res.status).toBe(201);
    directorToken = res.body.token;
  });

  test('Should login successfully', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'reader@test.com',
        password: 'password123'
      });
    
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('token');
  });
});

describe('Book Suggestions', () => {
  test('Should create a new book suggestion', async () => {
    const res = await request(app)
      .post('/api/suggestions')
      .set('Authorization', `Bearer ${readerToken}`)
      .send({
        title: 'Test Book',
        author: 'Test Author',
        isbn: '9781234567890',
        pitch: 'This would make a great movie because...',
        genre: ['thriller', 'mystery']
      });
    
    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('id');
    suggestionId = res.body.id;
  });

  test('Should get all suggestions', async () => {
    const res = await request(app)
      .get('/api/suggestions')
      .query({ genre: 'thriller' });
    
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBeTruthy();
    expect(res.body.length).toBeGreaterThan(0);
  });

  test('Should get a single suggestion', async () => {
    const res = await request(app)
      .get(`/api/suggestions/${suggestionId}`);
    
    expect(res.status).toBe(200);
    expect(res.body.title).toBe('Test Book');
  });

  test('Should upvote a suggestion', async () => {
    const res = await request(app)
      .post(`/api/suggestions/${suggestionId}/upvote`)
      .set('Authorization', `Bearer ${directorToken}`);
    
    expect(res.status).toBe(201);
  });

  test('Should prevent duplicate upvotes', async () => {
    const res = await request(app)
      .post(`/api/suggestions/${suggestionId}/upvote`)
      .set('Authorization', `Bearer ${directorToken}`);
    
    expect(res.status).toBe(400);
  });
});

describe('Comments', () => {
  test('Should add a comment to a suggestion', async () => {
    const res = await request(app)
      .post(`/api/comments/${suggestionId}`)
      .set('Authorization', `Bearer ${directorToken}`)
      .send({
        content: 'This would make an excellent film adaptation!'
      });
    
    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('id');
  });

  test('Should get comments for a suggestion', async () => {
    const res = await request(app)
      .get(`/api/comments/${suggestionId}`);
    
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBeTruthy();
    expect(res.body.length).toBeGreaterThan(0);
  });
});

describe('Search', () => {
  test('Should search suggestions', async () => {
    const res = await request(app)
      .get('/api/search')
      .query({
        q: 'Test Book',
        genre: 'thriller'
      });
    
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBeTruthy();
    expect(res.body.length).toBeGreaterThan(0);
  });

  test('Should return ranked search results', async () => {
    const res = await request(app)
      .get('/api/search')
      .query({
        q: 'thriller mystery',
        minUpvotes: 1
      });
    
    expect(res.status).toBe(200);
    expect(res.body[0]).toHaveProperty('rank');
  });
});

describe('Admin Functions', () => {
  beforeAll(async () => {
    // Create admin user
    const adminRes = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'admin@test.com',
        password: 'password123',
        username: 'testAdmin',
        role: 'admin'
      });
    adminToken = adminRes.body.token;
  });

  test('Should get pending suggestions', async () => {
    const res = await request(app)
      .get('/api/admin/suggestions/pending')
      .set('Authorization', `Bearer ${adminToken}`);
    
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBeTruthy();
  });

  test('Should update suggestion status', async () => {
    const res = await request(app)
      .put(`/api/admin/suggestions/${suggestionId}/status`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        status: 'approved'
      });
    
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('approved');
  });

  test('Should prevent non-admin from accessing admin routes', async () => {
    const res = await request(app)
      .get('/api/admin/suggestions/pending')
      .set('Authorization', `Bearer ${readerToken}`);
    
    expect(res.status).toBe(403);
  });
});

describe('Notifications', () => {
  test('Should get user notifications', async () => {
    const res = await request(app)
      .get('/api/notifications')
      .set('Authorization', `Bearer ${readerToken}`);
    
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBeTruthy();
  });

  test('Should mark notification as read', async () => {
    // First get a notification ID
    const notificationsRes = await request(app)
      .get('/api/notifications')
      .set('Authorization', `Bearer ${readerToken}`);
    
    const notificationId = notificationsRes.body[0].id;

    const res = await request(app)
      .put(`/api/notifications/${notificationId}/read`)
      .set('Authorization', `Bearer ${readerToken}`);
    
    expect(res.status).toBe(200);
    expect(res.body.read).toBe(true);
  });
});

describe('Integration Tests', () => {
  test('Full suggestion lifecycle', async () => {
    // 1. Create suggestion
    const suggestionRes = await request(app)
      .post('/api/suggestions')
      .set('Authorization', `Bearer ${readerToken}`)
      .send({
        title: 'Integration Test Book',
        author: 'Test Author',
        isbn: '9789876543210',
        pitch: 'A compelling story for the big screen...',
        genre: ['drama', 'romance']
      });
    
    const newSuggestionId = suggestionRes.body.id;
    
    // 2. Add upvotes
    await request(app)
      .post(`/api/suggestions/${newSuggestionId}/upvote`)
      .set('Authorization', `Bearer ${directorToken}`);
    
    // 3. Add comments
    await request(app)
      .post(`/api/comments/${newSuggestionId}`)
      .set('Authorization', `Bearer ${directorToken}`)
      .send({
        content: 'Great potential for adaptation!'
      });
    
    // 4. Admin approval
    const approvalRes = await request(app)
      .put(`/api/admin/suggestions/${newSuggestionId}/status`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        status: 'approved'
      });
    
    expect(approvalRes.status).toBe(200);
    expect(approvalRes.body.status).toBe('approved');
    
    // 5. Check notifications
    const notificationsRes = await request(app)
      .get('/api/notifications')
      .set('Authorization', `Bearer ${readerToken}`);
    
    expect(notificationsRes.body.some(n => n.type === 'status_change')).toBeTruthy();
  });
});

afterAll(async () => {
  // Clean up test data
  await db.query('DELETE FROM notifications');
  await db.query('DELETE FROM comments');
  await db.query('DELETE FROM upvotes');
  await db.query('DELETE FROM book_suggestions');
  await db.query('DELETE FROM users');
});