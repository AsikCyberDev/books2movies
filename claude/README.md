# Book to Movie Platform API

A RESTful API service that enables readers to suggest published books for movie adaptations and connects film industry professionals with potential adaptation opportunities.

## 🎯 Overview

The Book to Movie Platform serves as a bridge between passionate readers and film industry professionals. It allows readers to suggest books they believe would make great movies, while providing producers and directors with a curated source of pre-vetted literary content for potential adaptation.

### Key Features

- **Book Suggestions**: Readers can suggest published books for movie adaptation
- **Industry Access**: Film professionals can browse and filter suggestions
- **Kindle Integration**: Direct suggestions from e-reading platforms
- **Community Engagement**: Upvoting and commenting system
- **Original Stories**: Optional submission system for unpublished works

## 🚀 Getting Started

### Prerequisites

- Node.js 18+
- PostgreSQL 14+
- Redis (for caching and session management)
- AWS S3 (for file storage)

### Environment Variables

```bash
# Server Configuration
PORT=3000
NODE_ENV=development

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/booktomovie

# Authentication
JWT_SECRET=your-secret-key
JWT_EXPIRY=24h

# AWS Configuration
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-west-2
AWS_S3_BUCKET=your-bucket-name

# Redis Configuration
REDIS_URL=redis://localhost:6379

# External Integration
KINDLE_API_KEY=your-kindle-integration-key
```

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/book-to-movie-platform.git
cd book-to-movie-platform
```

2. Install dependencies:
```bash
npm install
```

3. Set up the database:
```bash
npm run db:migrate
npm run db:seed
```

4. Start the development server:
```bash
npm run dev
```

## 📖 API Documentation

Our API follows OpenAPI 3.1.0 specification. You can find the complete API documentation at `/docs` when running the server.

### Authentication

The API uses JWT (JSON Web Tokens) for authentication. Include the token in the Authorization header:

```http
Authorization: Bearer <your_jwt_token>
```

### User Roles

- **Reader**: Can suggest books and participate in community features
- **Director**: Industry professional who can browse and interact with suggestions
- **Admin**: Platform moderator with additional privileges

### Core Endpoints

#### Authentication
- `POST /auth/register` - Register a new user
- `POST /auth/login` - Authenticate user and receive JWT

#### Book Suggestions
- `POST /suggestions` - Create a new book suggestion
- `GET /suggestions` - List all suggestions with filtering
- `GET /suggestions/{id}` - Get specific suggestion details
- `PUT /suggestions/{id}` - Update a suggestion
- `POST /suggestions/{id}/upvote` - Upvote a suggestion
- `POST /suggestions/{id}/comments` - Comment on a suggestion

#### Search & Discovery
- `GET /search` - Search suggestions with advanced filtering
- `GET /suggestions/featured` - Get featured suggestions

#### Notifications
- `GET /notifications` - Get user notifications
- `PUT /notifications/{id}/read` - Mark notification as read

#### Admin Operations
- `GET /admin/suggestions/pending` - View pending suggestions
- `PUT /admin/suggestions/{id}/status` - Update suggestion status

### Rate Limiting

API requests are rate-limited to:
- 100 requests per minute for authenticated users
- 20 requests per minute for unauthenticated users

### Error Handling

The API uses conventional HTTP response codes:
- `2xx` - Success
- `4xx` - Client errors
- `5xx` - Server errors

Error responses follow this format:
```json
{
  "code": "ERROR_CODE",
  "message": "Human readable message",
  "details": {
    "field": "Additional information"
  }
}
```

## 🛠 Development

### Technology Stack

- **Framework**: Node.js with Express
- **Database**: PostgreSQL with Prisma ORM
- **Caching**: Redis
- **Storage**: AWS S3
- **Testing**: Jest
- **Documentation**: OpenAPI/Swagger

### Project Structure

```
.
├── src/
│   ├── config/         # Configuration files
│   ├── controllers/    # Request handlers
│   ├── middleware/     # Custom middleware
│   ├── models/         # Data models
│   ├── routes/         # Route definitions
│   ├── services/       # Business logic
│   ├── utils/          # Helper functions
│   └── app.js         # Application entry point
├── tests/             # Test files
├── prisma/            # Database schema and migrations
└── docs/              # Additional documentation
```

### Running Tests

```bash
# Run all tests
npm test

# Run tests with coverage
npm run test:coverage

# Run specific test suite
npm test -- users.test.js
```

### Database Migrations

```bash
# Create a new migration
npm run db:migrate:create

# Apply migrations
npm run db:migrate

# Rollback last migration
npm run db:rollback
```

## 🔒 Security

### API Security Measures

1. JWT-based authentication
2. Rate limiting
3. Input validation and sanitization
4. CORS configuration
5. Security headers (Helmet)
6. Request size limits
7. SQL injection prevention via ORM
8. XSS protection

### Data Privacy

- User passwords are hashed using bcrypt
- Personal data is encrypted at rest
- Regular security audits
- GDPR compliance measures

## 📄 License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Commit Message Format

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

## 📞 Support

- Documentation: [docs.booktomovie.example.com](https://docs.booktomovie.example.com)
- Email: support@booktomovie.example.com
- Bug Reports: GitHub Issues

## 🗺 Roadmap

- [ ] Mobile application support
- [ ] AI-powered book recommendation system
- [ ] Integration with additional e-reader platforms
- [ ] Rights management system
- [ ] Analytics dashboard for industry professionals

## 🙏 Acknowledgments

- Thanks to all our contributors
- Book industry partners
- Film industry advisors
- Open-source community