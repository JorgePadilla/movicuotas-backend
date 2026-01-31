# MOVICUOTAS API Documentation

**Base URL**: `https://movicuotas.com/api/v1`

**Version**: v1

## Overview

REST API for the MOVICUOTAS Flutter mobile application. Enables customers to view their loans, payment schedules, submit payments, and receive notifications.

---

## Authentication

All endpoints except `/auth/login` and `/auth/forgot_contract` require a valid JWT token.

### Headers

```http
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

### Token Details

- **Algorithm**: HS256
- **Expiration**: 30 days from issue
- **Payload**: `{ customer_id, exp, iat }`

---

## Error Responses

All errors follow this format:

```json
{
  "error": "Error message description"
}
```

### HTTP Status Codes

| Code | Description |
|------|-------------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request - Missing or invalid parameters |
| 401 | Unauthorized - Invalid or missing token |
| 404 | Not Found - Resource doesn't exist |
| 422 | Unprocessable Entity - Validation errors |

---

## Endpoints

### 1. Authentication

#### POST /auth/login

Authenticate a customer using their identification number.

**Authentication**: Not required

**Request Body**:

```json
{
  "auth": {
    "identification_number": "0801199012345"
  }
}
```

**Success Response** (200):

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "customer": {
    "id": 1,
    "identification_number": "0801199012345",
    "full_name": "Juan Carlos Pérez",
    "email": "juan@email.com",
    "phone": "+50489978918",
    "date_of_birth": "1990-05-15",
    "gender": "male",
    "address": "Col. Kennedy, Bloque A",
    "city": "Tegucigalpa",
    "status": "active"
  },
  "loan": {
    "id": 1,
    "contract_number": "MC-2026-0001",
    "customer_id": 1,
    "status": "active",
    "total_amount": 15000.00,
    "approved_amount": 15000.00,
    "down_payment_percentage": 20.0,
    "down_payment_amount": 3000.00,
    "financed_amount": 12000.00,
    "interest_rate": 18.0,
    "number_of_installments": 12,
    "start_date": "2026-01-01",
    "end_date": "2026-12-01",
    "branch_number": "001",
    "device": {
      "id": 1,
      "imei": "123456789012345",
      "brand": "Samsung",
      "model": "Galaxy A54",
      "phone_model_id": 5,
      "lock_status": "unlocked",
      "is_locked": false
    }
  }
}
```

**Error Response** (401):

```json
{
  "error": "Invalid credentials"
}
```

---

#### GET /auth/forgot_contract

Recover contract number via SMS. Sends the contract number to the customer's registered phone.

**Authentication**: Not required

**Query Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| phone | string | Yes | Customer's registered phone number |

**Example**:

```
GET /api/v1/auth/forgot_contract?phone=+50489978918
```

**Success Response** (200):

```json
{
  "message": "Contract number sent to +50489978918"
}
```

**Error Responses**:

- Customer not found (404):
```json
{
  "error": "Customer not found"
}
```

- No active loan (404):
```json
{
  "error": "No active loan found"
}
```

---

### 2. Dashboard

#### GET /dashboard

Get customer dashboard with active loan summary, next payment, and device status.

**Authentication**: Required

**Success Response** (200):

```json
{
  "customer": {
    "id": 1,
    "identification_number": "0801199012345",
    "full_name": "Juan Carlos Pérez",
    "email": "juan@email.com",
    "phone": "+50489978918",
    "date_of_birth": "1990-05-15",
    "gender": "male",
    "address": "Col. Kennedy, Bloque A",
    "city": "Tegucigalpa",
    "status": "active"
  },
  "loan": {
    "id": 1,
    "contract_number": "MC-2026-0001",
    "customer_id": 1,
    "status": "active",
    "total_amount": 15000.00,
    "approved_amount": 15000.00,
    "down_payment_percentage": 20.0,
    "down_payment_amount": 3000.00,
    "financed_amount": 12000.00,
    "interest_rate": 18.0,
    "number_of_installments": 12,
    "start_date": "2026-01-01",
    "end_date": "2026-12-01",
    "branch_number": "001",
    "device": {
      "id": 1,
      "imei": "123456789012345",
      "brand": "Samsung",
      "model": "Galaxy A54",
      "phone_model_id": 5,
      "lock_status": "unlocked",
      "is_locked": false
    }
  },
  "next_payment": {
    "id": 3,
    "loan_id": 1,
    "installment_number": 3,
    "due_date": "2026-03-01",
    "amount": 1166.67,
    "status": "pending",
    "paid_date": null,
    "days_overdue": 0,
    "is_overdue": false
  },
  "overdue_count": 0,
  "total_overdue_amount": 0.00,
  "device_status": {
    "imei": "123456789012345",
    "phone_model": "Samsung Galaxy A54",
    "status": "active",
    "is_blocked": false
  }
}
```

**Error Response** (404):

```json
{
  "error": "No active loan found"
}
```

---

### 3. Installments

#### GET /installments

Get complete payment schedule for the customer's active loan.

**Authentication**: Required

**Success Response** (200):

```json
{
  "installments": [
    {
      "id": 1,
      "loan_id": 1,
      "installment_number": 1,
      "due_date": "2026-01-01",
      "amount": 1166.67,
      "status": "paid",
      "paid_date": "2026-01-01",
      "days_overdue": 0,
      "is_overdue": false
    },
    {
      "id": 2,
      "loan_id": 1,
      "installment_number": 2,
      "due_date": "2026-02-01",
      "amount": 1166.67,
      "status": "paid",
      "paid_date": "2026-02-01",
      "days_overdue": 0,
      "is_overdue": false
    },
    {
      "id": 3,
      "loan_id": 1,
      "installment_number": 3,
      "due_date": "2026-03-01",
      "amount": 1166.67,
      "status": "pending",
      "paid_date": null,
      "days_overdue": 0,
      "is_overdue": false
    }
  ],
  "summary": {
    "total_installments": 12,
    "pending": 10,
    "paid": 2,
    "overdue": 0
  }
}
```

**Installment Statuses**:

| Status | Description |
|--------|-------------|
| pending | Payment not yet due or awaiting payment |
| paid | Payment completed and verified |
| overdue | Payment past due date and not paid |

**Error Response** (404):

```json
{
  "error": "No active loan found"
}
```

---

### 4. Payments

#### POST /payments

Submit a payment with optional receipt image. Payment starts in "pending" status until verified by admin.

**Authentication**: Required

**Request Body**:

```json
{
  "payment": {
    "installment_id": 3,
    "amount": 1166.67,
    "payment_date": "2026-03-01",
    "payment_method": "transfer",
    "receipt_image": "<base64_encoded_image>"
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| installment_id | integer | Yes | ID of the installment being paid |
| amount | decimal | Yes | Payment amount |
| payment_date | date | Yes | Date of payment (YYYY-MM-DD) |
| payment_method | string | No | Payment method: `cash`, `transfer`, `card`, `other`. Defaults to `transfer` |
| receipt_image | base64 | No | Base64 encoded receipt/transfer proof image |

**Success Response** (201):

```json
{
  "id": 15,
  "status": "pending",
  "message": "Payment submitted successfully. Please wait for verification."
}
```

**Error Responses**:

- Installment not found (404):
```json
{
  "error": "Installment not found"
}
```

- Validation error (422):
```json
{
  "error": "Amount must be greater than 0"
}
```

---

### 5. Notifications

#### GET /notifications

Get paginated list of customer notifications, ordered by most recent.

**Authentication**: Required

**Query Parameters**:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| page | integer | 1 | Page number |
| per_page | integer | 10 | Items per page |

**Example**:

```
GET /api/v1/notifications?page=1&per_page=20
```

**Success Response** (200):

```json
{
  "notifications": [
    {
      "id": 5,
      "title": "Pago Recibido",
      "message": "Tu pago de L. 1,166.67 ha sido verificado exitosamente.",
      "notification_type": "payment_confirmed",
      "is_read": false,
      "created_at": "2026-03-01T10:30:00Z",
      "data": {
        "payment_id": 15,
        "installment_number": 3
      }
    },
    {
      "id": 4,
      "title": "Recordatorio de Pago",
      "message": "Tu cuota #3 vence mañana. Monto: L. 1,166.67",
      "notification_type": "payment_reminder",
      "is_read": true,
      "created_at": "2026-02-28T09:00:00Z",
      "data": {
        "installment_id": 3,
        "due_date": "2026-03-01"
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

**Notification Types**:

| Type | Description |
|------|-------------|
| payment_reminder | Upcoming payment reminder |
| payment_confirmed | Payment verified successfully |
| payment_overdue | Payment is overdue |
| device_blocked | Device has been blocked |
| device_unblocked | Device has been unblocked |
| general | General announcements |

---

## Data Models

### Customer

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Unique identifier |
| identification_number | string | National ID number |
| full_name | string | Customer's full name |
| email | string | Email address |
| phone | string | Phone number (with country code) |
| date_of_birth | date | Birth date |
| gender | string | male/female |
| address | string | Street address |
| city | string | City name |
| status | string | active/inactive |

### Loan

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Unique identifier |
| contract_number | string | Contract number (MC-YYYY-XXXX) |
| customer_id | integer | Customer reference |
| status | string | pending/active/completed/defaulted |
| total_amount | decimal | Total loan amount |
| approved_amount | decimal | Approved credit amount |
| down_payment_percentage | decimal | Down payment % |
| down_payment_amount | decimal | Down payment amount |
| financed_amount | decimal | Amount to be financed |
| interest_rate | decimal | Annual interest rate |
| number_of_installments | integer | Total number of payments |
| start_date | date | Loan start date |
| end_date | date | Expected end date |
| branch_number | string | Selling branch code |
| device | object | Associated device |

### Device

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Unique identifier |
| imei | string | Device IMEI number |
| brand | string | Device brand |
| model | string | Device model |
| phone_model_id | integer | PhoneModel reference |
| lock_status | string | unlocked/pending/locked |
| is_locked | boolean | Whether device is currently locked |

### Installment

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Unique identifier |
| loan_id | integer | Loan reference |
| installment_number | integer | Sequential number (1, 2, 3...) |
| due_date | date | Payment due date |
| amount | decimal | Amount due |
| status | string | pending/paid/overdue |
| paid_date | date | Actual payment date (if paid) |
| days_overdue | integer | Days past due (0 if not overdue) |
| is_overdue | boolean | Whether payment is overdue |

### Notification

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Unique identifier |
| title | string | Notification title |
| message | string | Notification body |
| notification_type | string | Type category |
| is_read | boolean | Read status |
| created_at | datetime | Creation timestamp |
| data | object | Additional metadata |

---

## Rate Limiting

Currently no rate limiting is enforced. This may change in future versions.

## Versioning

The API is versioned via the URL path (`/api/v1/`). Breaking changes will result in a new version (`/api/v2/`).

---

## Testing

### cURL Examples

**Login**:
```bash
curl -X POST https://movicuotas.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"auth":{"identification_number":"0801199012345"}}'
```

**Get Dashboard**:
```bash
curl -X GET https://movicuotas.com/api/v1/dashboard \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Get Installments**:
```bash
curl -X GET https://movicuotas.com/api/v1/installments \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Submit Payment**:
```bash
curl -X POST https://movicuotas.com/api/v1/payments \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"payment":{"installment_id":3,"amount":1166.67,"payment_date":"2026-03-01"}}'
```

**Get Notifications**:
```bash
curl -X GET "https://movicuotas.com/api/v1/notifications?page=1&per_page=10" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

*Last updated: 2026-01-05*
