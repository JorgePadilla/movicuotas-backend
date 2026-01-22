# Vendor Workflow - 18 Steps

Complete flow for processing a phone sale with credit in the MOVICUOTAS system.

---

## Step 1: Login
**File:** `app/views/sessions/new.html.erb`

Vendor authenticates with email and password to access the vendor portal.

---

## Step 2: Customer Search
**File:** `app/views/vendor/customer_search/new.html.erb`

Vendor searches for an existing customer by:
- Identity number (Número de Identidad)
- Phone number

If customer exists with approved credit, proceeds to device selection. If not, starts new credit application.

---

## Step 3: Datos Generales (General Data)
**File:** `app/views/vendor/credit_applications/new.html.erb`

Capture customer personal information:
- Identity number (Número de Identidad)
- Full name
- Gender
- Date of birth (validates age 21-60 years)
- Address, city, department
- Phone number
- Email

Creates customer record and credit application.

---

## Step 4: Fotografías (Photos)
**File:** `app/views/vendor/credit_applications/photos.html.erb`

Capture 3 photos in a single screen:

| Photo | Camera | Description |
|-------|--------|-------------|
| ID Frontal | Back camera | Front of identity card |
| ID Reverso | Back camera | Back of identity card |
| Verificación Facial | Front camera | Selfie holding ID card |

Each photo has Start/Capture/Retake buttons. All 3 required to proceed.

---

## Step 5: Verificación OTP
**File:** `app/views/vendor/credit_applications/verify_otp.html.erb`

SMS verification of customer identity:
- 4-digit code sent to customer's phone
- 10-minute expiration
- Maximum 5 attempts
- Customer dictates code to vendor

**Dev bypass:** Code "1001" works in development environment.

---

## Step 6: Datos Laborales (Employment Data)
**File:** `app/views/vendor/credit_applications/employment.html.erb`

Capture employment information:

**Employment Status:**
- Empleado (Employed)
- Independiente (Self-employed)
- Desempleado (Unemployed)
- Estudiante (Student)
- Jubilado (Retired)

**Salary Range (Lempiras):**
- Menos de 10,000
- 10,000 - 20,000
- 20,000 - 30,000
- 30,000 - 40,000
- Más de 40,000

---

## Step 7: Resumen Solicitud (Application Summary)
**File:** `app/views/vendor/credit_applications/summary.html.erb`

Review all entered data before submission:
- Customer information
- Photo status (all 3 attached)
- Employment data
- Submit button triggers automatic credit evaluation

---

## Step 8: Credit Result (Automatic)
**Files:**
- `app/views/vendor/credit_applications/approved.html.erb`
- `app/views/vendor/credit_applications/rejected.html.erb`

**Automatic credit evaluation** via `CreditApprovalService`:

**Validation Rules:**
- Age must be 21-60 years
- All 3 photos must be attached
- OTP must be verified

**Approved Amount** (based on salary range):
| Salary Range | Credit Amount |
|--------------|---------------|
| < 10,000 | L. 5,000 - 8,000 |
| 10,000 - 20,000 | L. 8,000 - 12,000 |
| 20,000 - 30,000 | L. 12,000 - 18,000 |
| 30,000 - 40,000 | L. 18,000 - 25,000 |
| > 40,000 | L. 25,000 - 35,000 |

**Note:** Approved amount is hidden from vendor/customer. Only used for device selection validation.

If approved, shows application number (format: `APP-YYYYMMDD-XXXXXX`).

---

## Step 9: Application Recovery
**File:** `app/views/vendor/application_recovery/show.html.erb`

Retrieve approved credit application to continue with purchase:
- Search by application number or customer ID
- Shows approval status and details
- Proceeds to device selection

---

## Step 10: Device Selection
**File:** `app/views/vendor/device_selections/new.html.erb`

Customer selects the phone to purchase:
- Browse available phone models
- Filter by price (within approved amount)
- View specifications
- Select specific unit (IMEI, color)

---

## Step 11: Purchase Confirmation
**File:** `app/views/vendor/device_selections/confirmation.html.erb`

Confirm selected device details:
- Phone model and specifications
- IMEI number
- Color selected
- Price confirmation

---

## Step 12: Payment Calculator
**File:** `app/views/vendor/payment_calculators/new.html.erb`

Calculate and select payment plan:

**Down Payment Options:** 10%, 15%, 20%, 25%, 30%

**Note:** Ages 50-60 can only select 40% or 50% down payment.

**Installment Periods:** 6, 8, 10, or 12 biweekly payments

Shows:
- Down payment amount
- Biweekly payment amount
- Total cost with interest
- Payment schedule

---

## Step 13: Contract Display
**File:** `app/views/vendor/contracts/show.html.erb`

Display full contract for customer review:
- Terms and conditions
- Payment schedule
- Device information
- **Activation code** (6-character alphanumeric)
- Customer and vendor signatures area

---

## Step 14: Digital Signature
**File:** `app/views/vendor/contracts/signature.html.erb`

Capture customer's digital signature:
- Touch/mouse signature canvas
- Customer signs with finger on screen
- Signature attached to contract
- Legal validity per Honduras Electronic Signature Law (Decreto No. 101-2013)

---

## Step 15: Down Payment (Prima)
**File:** `app/views/vendor/down_payments/show.html.erb`

Collect down payment from customer:

| Method | Process |
|--------|---------|
| **Efectivo** | Vendor confirms receipt with checkbox |
| **Depósito** | Upload receipt image (pending admin verification) |

Shows amount to collect. Proceeds to QR MDM after confirmation.

---

## Step 16: QR Code MDM
**File:** `app/views/vendor/mdm_blueprints/show.html.erb`

Display QR code for MDM (Mobile Device Management) configuration:
- Large QR code for scanning
- Instructions for customer to scan with new phone
- Downloads and installs MDM protection app
- Device information (IMEI, brand, model)
- Option to download QR as image

**Purpose:** Installs device management software that allows remote locking if payments are missed.

---

## Step 17: Final Checklist
**File:** `app/views/vendor/mdm_checklists/show.html.erb`

Verify all configuration is complete before device handoff:

| Checkbox | Description |
|----------|-------------|
| BluePrint escaneado | Customer scanned QR, MDM configuration started |
| App MDM instalada | MDM app shows "Dispositivo protegido" |
| App MOVICUOTAS activada | Customer entered activation code in app |

**Activation Code Display:** Shows 6-character code for customer to enter in MOVICUOTAS mobile app.

All checkboxes must be marked to proceed.

---

## Step 18: Thank You (Gracias)
**File:** `app/views/vendor/contracts/success.html.erb`

Final success screen:
- Blue heart icon
- "¡Gracias por tu Confianza!"
- "Es un placer servirte. Estamos aquí para apoyarte en cada paso."
- "MOVICUOTAS - Tu Crédito, Tu Móvil"
- Credit summary (customer, device, contract, next payment)
- Activation code reference
- **Download Contract** button (PDF)
- **Nueva Búsqueda de Cliente** button to start new sale

---

## Flow Diagram

```
[1] Login
    ↓
[2] Customer Search ─────────────────────┐
    ↓                                    ↓
    (new customer)                  (existing with approval)
    ↓                                    ↓
[3] Datos Generales                      │
    ↓                                    │
[4] Fotografías (3 photos)               │
    ↓                                    │
[5] Verificación OTP                     │
    ↓                                    │
[6] Datos Laborales                      │
    ↓                                    │
[7] Resumen Solicitud                    │
    ↓                                    │
[8] Credit Result (auto) ────────────────┤
    ↓                                    │
[9] Application Recovery ←───────────────┘
    ↓
[10] Device Selection
    ↓
[11] Purchase Confirmation
    ↓
[12] Payment Calculator
    ↓
[13] Contract Display
    ↓
[14] Digital Signature
    ↓
[15] Down Payment (Prima)
    ↓
[16] QR Code MDM
    ↓
[17] Final Checklist
    ↓
[18] Thank You / Complete
    ↓
[2] Nueva Búsqueda (New Sale)
```

---

## Key Features

### Automatic Credit Evaluation
- No manual credit check step
- System evaluates automatically on submission
- Based on age validation and salary range
- Approved amount calculated but hidden from UI

### Activation Code System
- Generated automatically when device is created
- 6-character uppercase alphanumeric (e.g., "A1B2C3")
- Displayed in: Contract PDF, Step 17 Checklist
- Customer enters in MOVICUOTAS mobile app to link FCM token
- Enables push notifications for payment reminders

### MDM Protection
- QR code scanned by customer's new phone
- Installs device management software
- Allows remote device locking for delinquent accounts
- Shows "Dispositivo protegido" when configured

### Age Restrictions
- Minimum age: 21 years
- Maximum age: 60 years
- Ages 50-60: Limited to 40% or 50% down payment only

---

## Navigation Reference

| Step | Back Button | Forward Button |
|------|-------------|----------------|
| 15 Prima | ← Firma | Confirmar Prima → |
| 16 QR MDM | ← Prima | Continuar a Checklist → |
| 17 Checklist | ← QR | Finalizar Venta → |
| 18 Gracias | (none) | Nueva Búsqueda |
