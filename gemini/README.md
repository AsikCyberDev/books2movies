# Book-to-Movie Suggestion Platform API

[![OpenAPI 3.1.0](https://img.shields.io/badge/OpenAPI-3.1.0-green.svg)](https://spec.openapis.org/oas/v3.1.0)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)](https://your-build-system.com/build-status)  [![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT) ## Introduction

This document describes the API for the Book-to-Movie Suggestion Platform, a web application where book readers can suggest published books that they believe should be adapted into movies. The platform allows industry professionals (directors, producers) to discover these suggestions, engage in discussions, and potentially pursue adaptation rights.

**Key Features:**

*   **Book Suggestions:** Readers can suggest books by providing metadata (title, author, ISBN/ASIN) and a "pitch" explaining why the book is adaptation-worthy.
*   **Upvoting and Commenting:** Users can upvote suggestions they like and add comments to discuss a book's potential.
*   **Search and Filtering:** Directors and producers can easily search for suggestions by title, author, genre, and other criteria, as well as sort by popularity (upvotes) or date.
*   **User Roles:** The platform supports different user roles:
    *   **Reader:** Can suggest books, upvote, and comment.
    *   **Director/Producer:** Can search, browse, upvote, comment, and potentially express interest in suggestions.
    *   **Admin:** Can moderate content, manage users, and perform editorial tasks.
*   **Kindle Integration:** A dedicated endpoint allows seamless integration with external services like Kindle to receive book suggestions directly (e.g., via a "Suggest for Movie" button).
*   **Original Story Submissions (Optional):** Aspiring authors can submit original stories for consideration.
*   **Notifications:** Users receive notifications about relevant activities (e.g., comments on their suggestions).

## Getting Started

### Prerequisites

*   A compatible API client (e.g., Postman, Insomnia, or a programming language with HTTP libraries).
*   An API key or authentication token (if required for certain endpoints).

### Installation

1.  **Clone the repository:**

    ```bash
    git clone [invalid URL removed]  # Replace with your repository URL
    cd book-to-movie-api
    ```

2.  **Install dependencies:** (This step depends on your backend technology)

    ```bash
    npm install  # Or yarn install, pip install -r requirements.txt, etc.
    ```

3.  **Configure the environment:**
    *   Set up environment variables for database connection, API keys, etc. (usually in a `.env` file).

4.  **Run the application:**

    ```bash
    npm start  # Or yarn start, python manage.py runserver, etc.
    ```

### API Documentation

The complete API specification is available in the `openapi.yaml` file (OpenAPI 3.1.0 format). You can view it using tools like:

*   **Swagger Editor:** [https://editor.swagger.io/](https://editor.swagger.io/)
*   **Redoc:** [https://redoc.ly/](https://redoc.ly/)
*   **Postman:** Import the `openapi.yaml` file into Postman.

## API Endpoints

The API is organized into the following main sections:

### Authentication (`/auth`)

*   `/auth/register`: Register a new user (Reader, Director, or Admin).
*   `/auth/login`: Log in to obtain JWT access and refresh tokens.
*   `/auth/refresh`: Refresh an expired access token using a refresh token.
*   `/auth/logout`: Invalidate the current user's tokens.

### Users (`/users`)

*   `/users/{userId}`: Get a user's profile.
*   `/users`: List all users (Admin only).
*   `/users/{userId}`: Update a user's profile (Admin or the user themselves).

### Book Suggestions (`/book-suggestions`)

*   `/book-suggestions`: Create a new book suggestion.
*   `/book-suggestions`: Get a list of book suggestions (with pagination).
*   `/book-suggestions/{suggestionId}`: Get details of a specific suggestion.
*   `/book-suggestions/{suggestionId}`: Update a book suggestion (author or Admin).
*   `/book-suggestions/{suggestionId}`: Delete a book suggestion (author or Admin).

### Upvotes (`/book-suggestions/{suggestionId}/upvote`, `/book-suggestions/{suggestionId}/downvote`)

*   `/book-suggestions/{suggestionId}/upvote`: Upvote a book suggestion.
*   `/book-suggestions/{suggestionId}/downvote`: Remove an upvote.

### Comments (`/book-suggestions/{suggestionId}/comments`)

*   `/book-suggestions/{suggestionId}/comments`: Add a comment to a suggestion.
*   `/book-suggestions/{suggestionId}/comments`: Get comments for a suggestion (with pagination).

### Search & Discovery (`/search`)

*   `/search`: Search and filter book suggestions by title, author, genre, and sort by upvotes or date.

### Kindle Integration (`/kindle/suggest`)

*   `/kindle/suggest`: Receive a book suggestion from an external service (e.g., Kindle).

### Original Stories (`/original-stories`) (Optional)

*   `/original-stories`: Create a new original story.
*   `/original-stories/{storyId}`: Get, update, or delete an original story.

### Admin (`/admin`)

*   `/admin/suggestions/pending`: Get pending book suggestions (Admin only).
*   `/admin/suggestions/{suggestionId}/approve`: Approve a suggestion (Admin only).
*   `/admin/suggestions/{suggestionId}/reject`: Reject a suggestion (Admin only).

### Notifications (`/notifications`)

*   `/notifications`: Get user notifications (with pagination).
*   `/notifications/{notificationId}/mark-as-read`: Mark a notification as read.

## Authentication

This API uses JWT (JSON Web Tokens) for authentication.

1.  **Obtain Tokens:** After successful registration or login (`/auth/register`, `/auth/login`), you will receive an `accessToken` and a `refreshToken`.
2.  **Include in Headers:** Include the `accessToken` in the `Authorization` header for all subsequent requests that require authentication:

    ```
    Authorization: Bearer <your_access_token>
    ```

3.  **Token Refresh:** When the `accessToken` expires, use the `/auth/refresh` endpoint with your `refreshToken` to get a new `accessToken`.

## Error Handling

The API uses standard HTTP status codes to indicate success or failure:

*   **2xx (Success):**
    *   `200 OK`: The request was successful.
    *   `201 Created`: A new resource was created.
    *   `204 No Content`: The request was successful, but there is no content to return (e.g., successful delete).
*   **4xx (Client Error):**
    *   `400 Bad Request`: Invalid input or request format.
    *   `401 Unauthorized`: Invalid or missing authentication credentials.
    *   `403 Forbidden`: The user does not have permission to access the resource.
    *   `404 Not Found`: The requested resource was not found.
    *   `409 Conflict`: The request could not be completed due to a conflict (e.g., duplicate resource).
*   **5xx (Server Error):**
    *   `500 Internal Server Error`: An unexpected error occurred on the server.

Error responses typically include a JSON body with an `code` and a `message` providing more details about the error.

**Example Error Response:**

```json
{
  "code": "INVALID_INPUT",
  "message": "The provided email address is not valid."
}