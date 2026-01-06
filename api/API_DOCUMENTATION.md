# Minecraft Church Verification System API Documentation

## Overview

This API provides endpoints for managing the Minecraft Church verification system, including code generation, request submission, admin approval, and access grant management.

## Base URL

```
http://localhost:3000
```

## Authentication

The API uses two types of authentication:

1. **API Secret** (`X-API-Secret` header) - Used by Denizen scripts and server-side operations
2. **Admin Token** (`X-Admin-Token` header) - Used for admin operations like approving/rejecting requests

Set these in your `.env` file:
```env
API_SECRET=your_secure_random_secret_here_minimum_32_characters
ADMIN_TOKEN=your_admin_approval_token_here
```

## Endpoints

### Health Check

**GET** `/health`

Check API and database connection status.

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "database": "connected",
  "version": "1.0.0"
}
```

---

### Verification Codes

#### Generate Code

**POST** `/api/codes/generate`

Generate a new verification code for a child player.

**Headers:**
- `X-API-Secret`: API secret for authentication

**Body:**
```json
{
  "child_name": "PlayerName",
  "child_uuid": "550e8400-e29b-41d4-a716-446655440000" // optional
}
```

**Response:**
```json
{
  "success": true,
  "code": "ABC123",
  "child_name": "PlayerName",
  "expires_at": "2024-01-01T00:15:00.000Z",
  "expires_in_minutes": 15
}
```

---

### Verification Requests

#### Submit Request

**POST** `/api/requests/submit`

Submit a verification request from the Wix form.

**Body:**
```json
{
  "child_name": "PlayerName",
  "adult_name": "AdultName", // optional
  "code": "ABC123",
  "parent_name": "Parent Full Name",
  "parent_email": "parent@example.com",
  "consent": true,
  "church": "Church Name", // optional
  "adult_join": false // optional
}
```

**Response:**
```json
{
  "success": true,
  "request_id": 1,
  "message": "Verification request submitted successfully. Awaiting admin approval.",
  "status": "pending"
}
```

#### Get All Requests

**GET** `/api/requests?status=pending&limit=50&offset=0`

Get all verification requests (with optional filtering).

**Headers:**
- `X-Admin-Token`: Admin token for authentication

**Query Parameters:**
- `status` (optional): Filter by status (`pending`, `approved`, `rejected`, `processed`)
- `limit` (optional): Number of results (default: 50)
- `offset` (optional): Pagination offset (default: 0)

**Response:**
```json
{
  "success": true,
  "count": 10,
  "requests": [...]
}
```

#### Get Request by ID

**GET** `/api/requests/:id`

Get a specific verification request.

**Headers:**
- `X-Admin-Token`: Admin token for authentication

**Response:**
```json
{
  "success": true,
  "request": {...}
}
```

#### Approve Request

**POST** `/api/requests/:id/approve`

Approve a verification request and create access grants.

**Headers:**
- `X-Admin-Token`: Admin token for authentication

**Body:**
```json
{
  "approved_by": "AdminUsername",
  "notes": "Approved after review" // optional
}
```

**Response:**
```json
{
  "success": true,
  "message": "Verification request approved",
  "request_id": 1,
  "grants_created": 1
}
```

#### Reject Request

**POST** `/api/requests/:id/reject`

Reject a verification request.

**Headers:**
- `X-Admin-Token`: Admin token for authentication

**Body:**
```json
{
  "approved_by": "AdminUsername",
  "notes": "Rejection reason (required)"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Verification request rejected",
  "request_id": 1
}
```

---

### Access Grants

#### Get Pending Grants

**GET** `/api/grants/pending`

Get all pending access grants (for Denizen polling).

**Headers:**
- `X-API-Secret`: API secret for authentication

**Response:**
```json
{
  "success": true,
  "count": 5,
  "grants": [...]
}
```

#### Mark Grant as Applied

**POST** `/api/grants/:id/applied`

Mark a grant as successfully applied (after Denizen applies it via LuckPerms).

**Headers:**
- `X-API-Secret`: API secret for authentication

**Body:**
```json
{
  "applied_by": "denizen_script" // optional
}
```

**Response:**
```json
{
  "success": true,
  "message": "Grant marked as applied",
  "grant_id": 1
}
```

#### Mark Grant as Failed

**POST** `/api/grants/:id/failed`

Mark a grant as failed (if Denizen fails to apply it).

**Headers:**
- `X-API-Secret`: API secret for authentication

**Body:**
```json
{
  "error": "Error message describing what went wrong"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Grant marked as failed",
  "grant_id": 1
}
```

---

### Known Players

#### Register Player

**POST** `/api/players/register`

Register or update a known player.

**Headers:**
- `X-API-Secret`: API secret for authentication

**Body:**
```json
{
  "player_name": "PlayerName",
  "uuid": "550e8400-e29b-41d4-a716-446655440000", // optional
  "platform": "java" // optional: "java", "bedrock", or "unknown"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Player registered",
  "player_name": "PlayerName",
  "action": "created" // or "updated"
}
```

#### Get Player

**GET** `/api/players/:player_name`

Get player information.

**Response:**
```json
{
  "success": true,
  "player": {...}
}
```

---

## Error Responses

All endpoints return errors in the following format:

```json
{
  "error": "Error type",
  "message": "Human-readable error message",
  "details": [...] // optional, for validation errors
}
```

**Common HTTP Status Codes:**
- `200` - Success
- `201` - Created
- `400` - Bad Request (validation error)
- `401` - Unauthorized (missing or invalid authentication)
- `404` - Not Found
- `500` - Internal Server Error

---

## Example Usage

### Generate a verification code (from Denizen script)

```javascript
// Denizen script example
- http get "http://localhost:3000/api/codes/generate"
  method:post
  headers:
    X-API-Secret:your_secret_here
  data:
    child_name:<player.name>
    child_uuid:<player.uuid>
```

### Submit a verification request (from Wix form)

```javascript
// JavaScript fetch example
fetch('http://localhost:3000/api/requests/submit', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    child_name: 'PlayerName',
    code: 'ABC123',
    parent_name: 'Parent Name',
    parent_email: 'parent@example.com',
    consent: true
  })
});
```

### Poll for pending grants (from Denizen script)

```javascript
// Denizen script example
- http get "http://localhost:3000/api/grants/pending"
  headers:
    X-API-Secret:your_secret_here
```

---

## Security Notes

1. **Never expose API secrets or admin tokens** in client-side code
2. **Use HTTPS in production** to encrypt API communications
3. **Restrict CORS origins** in production (set `CORS_ORIGIN` in `.env`)
4. **Keep secrets secure** - generate strong random secrets:
   ```bash
   openssl rand -base64 32
   ```

---

## Testing

Test the API connection:
```bash
node test-connection.js
```

Start the server:
```bash
npm start
```

Or in development:
```bash
npm run dev
```
