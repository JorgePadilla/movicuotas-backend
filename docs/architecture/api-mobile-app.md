# Phase 6: Mobile API Documentation

## Overview

Phase 6 introduces the REST API for the Flutter mobile application. The API provides customer endpoints for managing loans, payments, and receiving notifications.

**API Version**: v1
**Base URL**: `https://api.movicuotas.com/api/v1`
**Authentication**: JWT Bearer Token

## Authentication

### JWT Token Format

Tokens are valid for 30 days from issuance.

```
Header: Authorization: Bearer {token}
```

### Token Payload

```json
{
  "customer_id": 123,
  "exp": 1735689600,
  "iat": 1704153600
}
```

## Endpoints

### 1. Customer Authentication

#### Login
```
POST /auth/login
```

**Description**: Authenticate customer using identification number

**Request Body**:
```json
{
  "auth": {
    "identification_number": "1234567890123"
  }
}
```

**Response** (200 OK):
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "customer": {
    "id": 1,
    "identification_number": "1234567890123",
    "full_name": "Juan Pérez",
    "email": "juan@example.com",
    "phone": "12345678",
    "date_of_birth": "1990-01-15",
    "gender": "male",
    "address": "Calle Principal 123",
    "city": "San Salvador",
    "status": "active"
  },
  "loan": {
    "id": 10,
    "contract_number": "CONT-001",
    "customer_id": 1,
    "status": "active",
    "total_amount": 900.00,
    "approved_amount": 900.00,
    "down_payment_percentage": 30,
    "down_payment_amount": 270.00,
    "financed_amount": 630.00,
    "interest_rate": 12.5,
    "number_of_installments": 12,
    "start_date": "2024-01-01",
    "end_date": "2024-12-31",
    "branch_number": "BR01",
    "device": {
      "id": 5,
      "imei": "123456789012345",
      "brand": "Apple",
      "model": "iPhone 14",
      "phone_model_id": 1,
      "lock_status": "unlocked",
      "is_locked": false
    }
  }
}
```

**Error Response** (401 Unauthorized):
```json
{
  "error": "Invalid credentials"
}
```

#### Forgot Contract Number
```
GET /auth/forgot_contract?phone=12345678
```

**Description**: Send contract number via SMS to customer's phone

**Query Parameters**:
- `phone` (required): Customer's 8-digit phone number

**Response** (200 OK):
```json
{
  "message": "Contract number sent to 12345678"
}
```

**Error Response** (404 Not Found):
```json
{
  "error": "Customer not found"
}
```

### 2. Customer Dashboard

#### Get Dashboard
```
GET /dashboard
```

**Authentication**: Required (Bearer Token)

**Description**: Get customer's dashboard with loan and payment summary

**Response** (200 OK):
```json
{
  "customer": {
    "id": 1,
    "identification_number": "1234567890123",
    "full_name": "Juan Pérez",
    "email": "juan@example.com",
    "phone": "12345678",
    "date_of_birth": "1990-01-15",
    "gender": "male",
    "address": "Calle Principal 123",
    "city": "San Salvador",
    "status": "active"
  },
  "loan": {
    "id": 10,
    "contract_number": "CONT-001",
    "customer_id": 1,
    "status": "active",
    "total_amount": 900.00,
    "approved_amount": 900.00,
    "down_payment_percentage": 30,
    "down_payment_amount": 270.00,
    "financed_amount": 630.00,
    "interest_rate": 12.5,
    "number_of_installments": 12,
    "start_date": "2024-01-01",
    "end_date": "2024-12-31",
    "branch_number": "BR01",
    "device": {
      "id": 5,
      "imei": "123456789012345",
      "brand": "Apple",
      "model": "iPhone 14",
      "phone_model_id": 1,
      "lock_status": "unlocked",
      "is_locked": false
    }
  },
  "next_payment": {
    "id": 1,
    "loan_id": 10,
    "installment_number": 1,
    "due_date": "2024-02-15",
    "amount": 75.00,
    "status": "pending",
    "paid_date": null,
    "days_overdue": 0,
    "is_overdue": false
  },
  "overdue_count": 0,
  "total_overdue_amount": 0.00,
  "device_status": {
    "imei": "123456789012345",
    "phone_model": "iPhone 14",
    "status": "active",
    "is_blocked": false
  }
}
```

### 3. Payment Schedule

#### Get Installments
```
GET /installments
```

**Authentication**: Required (Bearer Token)

**Description**: Get all installments for customer's active loan

**Query Parameters** (Optional):
- `page` (default: 1): Page number for pagination
- `per_page` (default: 10): Items per page

**Response** (200 OK):
```json
{
  "installments": [
    {
      "id": 1,
      "loan_id": 10,
      "installment_number": 1,
      "due_date": "2024-02-15",
      "amount": 75.00,
      "status": "pending",
      "paid_date": null,
      "days_overdue": 0,
      "is_overdue": false
    },
    {
      "id": 2,
      "loan_id": 10,
      "installment_number": 2,
      "due_date": "2024-03-15",
      "amount": 75.00,
      "status": "pending",
      "paid_date": null,
      "days_overdue": 0,
      "is_overdue": false
    }
  ],
  "summary": {
    "total_installments": 12,
    "pending": 11,
    "paid": 1,
    "overdue": 0
  }
}
```

### 4. Payment Submission

#### Submit Payment
```
POST /payments
```

**Authentication**: Required (Bearer Token)

**Description**: Submit a payment with optional receipt image

**Request Body**:
```json
{
  "payment": {
    "installment_id": 1,
    "amount": 75.00,
    "payment_date": "2024-01-20",
    "receipt_image": "<binary_image_data>"
  }
}
```

**Response** (201 Created):
```json
{
  "id": 100,
  "status": "pending",
  "message": "Payment submitted successfully. Please wait for verification."
}
```

**Error Response** (422 Unprocessable Entity):
```json
{
  "error": "Payment validation failed"
}
```

### 5. Notifications

#### Get Notifications
```
GET /notifications?page=1&per_page=10
```

**Authentication**: Required (Bearer Token)

**Description**: Get customer's notification history with pagination

**Query Parameters**:
- `page` (optional, default: 1): Page number
- `per_page` (optional, default: 10): Items per page

**Response** (200 OK):
```json
{
  "notifications": [
    {
      "id": 1,
      "title": "Payment Received",
      "message": "Your payment of L. 75.00 has been received",
      "notification_type": "payment",
      "is_read": false,
      "created_at": "2024-01-20T10:30:00Z",
      "data": {
        "installment_id": 1,
        "amount": 75.00
      }
    },
    {
      "id": 2,
      "title": "Payment Reminder",
      "message": "Your next payment of L. 75.00 is due on 2024-02-15",
      "notification_type": "reminder",
      "is_read": true,
      "created_at": "2024-01-15T08:00:00Z",
      "data": {
        "installment_id": 2
      }
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 3,
    "total_count": 25,
    "per_page": 10
  }
}
```

## Error Handling

### HTTP Status Codes

- `200 OK` - Successful request
- `201 Created` - Resource created successfully
- `400 Bad Request` - Invalid request parameters
- `401 Unauthorized` - Missing or invalid authentication token
- `404 Not Found` - Resource not found
- `422 Unprocessable Entity` - Validation error
- `500 Internal Server Error` - Server error

### Error Response Format

```json
{
  "error": "Error message describing what went wrong"
}
```

## Rate Limiting

API requests are rate limited to:
- 100 requests per minute for authenticated endpoints
- 10 requests per minute for authentication endpoints

## Data Types

### Date Format
All dates use ISO 8601 format: `YYYY-MM-DD`

### DateTime Format
All datetimes use ISO 8601 format: `YYYY-MM-DDTHH:MM:SSZ`

### Currency
All monetary amounts are in Lempiras (L.) and use decimal notation with 2 decimal places.

## Security

1. **HTTPS Required**: All API endpoints must be accessed over HTTPS
2. **JWT Authentication**: Tokens must be included in the Authorization header
3. **Token Expiration**: Tokens expire after 30 days and must be refreshed via login
4. **No Sensitive Data in Logs**: Passwords and tokens are never logged
5. **Input Validation**: All inputs are validated before processing
6. **Rate Limiting**: API requests are rate limited to prevent abuse

## Implementation Notes

### JWT Token Generation

Tokens are generated on successful login and are valid for 30 days. The token payload includes:
- Customer ID
- Expiration timestamp
- Issued at timestamp

### Payment Submission Flow

1. Customer submits payment via `/payments` endpoint
2. Payment is created with `pending` status
3. Notification is sent to admin for verification
4. Admin verifies and updates payment status
5. Customer receives notification confirming payment

### Error Handling

The API uses HTTP status codes and JSON error responses to communicate errors. All error responses follow the standard format shown above.

## Testing

### Authentication Test
```bash
curl -X POST https://api.movicuotas.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "auth": {
      "identification_number": "1234567890123"
    }
  }'
```

### Dashboard Request
```bash
curl -X GET https://api.movicuotas.com/api/v1/dashboard \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..."
```

## Future Enhancements

1. **Payment Methods**: Support for multiple payment methods (credit card, bank transfer, mobile money)
2. **Biometric Authentication**: Face ID and fingerprint authentication
3. **Payment Analytics**: Spending trends and payment history analytics
4. **Customer Support**: In-app chat and ticket system
5. **Device Management**: Remote device unlock requests
6. **Notification Preferences**: Customizable notification settings
7. **Multi-language Support**: Localization for different languages
8. **Offline Mode**: Offline access to basic information

## Support

For API issues or questions, contact the development team at api-support@movicuotas.com
