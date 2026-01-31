### Vendor Workflow (18-Screen Process)

**CRITICAL NAVIGATION FLOW:**
```
Login (Step 1) → Customer Search (Step 2 - MAIN SCREEN) → [Dashboard accessible from menu]
```

#### Step 1: Login
Standard authentication for vendor users.

**UI Elements:**
- Email input field
- Password input field
- "Iniciar Sesión" button

**Next:** Step 2 (Buscar Cliente - Main Screen)

---

#### Step 2: Buscar Cliente (Main Screen)
**CRITICAL:** This is the main screen after login, NOT the dashboard.

**Primary Function:** Search for customer by identification number across ALL stores.

**UI Elements:**
- Large search bar: "Número de Identidad del Cliente"
- Prominent button: "Buscar en TODAS las tiendas"
- Navigation menu (sidebar/header):
  - 📊 Dashboard (accessible from menu)
  - 👥 Clientes
  - 💰 Préstamos
  - 💳 Pagos
  - 📋 Reportes

**Business Logic:**
```ruby
def search_customer(identification_number)
  # Check active loans across ALL branches
  active_loan = Loan.joins(:customer)
                   .where(customers: { identification_number: identification_number })
                   .where(status: 'active')
                   .first

  if active_loan
    {
      blocked: true,
      message: "Cliente tiene crédito activo en tienda #{active_loan.branch_number}",
      contract_number: active_loan.contract_number,
      alert_color: "red",
      action: "show_blocked_screen" # Step 3a
    }
  else
    {
      blocked: false,
      message: "Cliente disponible para nuevo crédito",
      alert_color: "green",
      action: "show_available_screen" # Step 3b
    }
  end
end
```

**UI Response:**
- **If blocked:** Show Step 3a
- **If available:** Show Step 3b

**Notes:**
- Search is the PRIMARY action
- Dashboard is SECONDARY, accessible via menu
- This screen is the "home" for vendors
- Always returns here after completing a sale

---

#### Step 3a: Cliente Bloqueado (If has active loan)
**Screen Type:** Error/Blocking

**UI Elements:**
- Red alert banner (`#ef4444`)
- Message: "Cliente tiene crédito activo. Finaliza el pago de tus Movicuotas para aplicar a más créditos!"
- Display: Contract number, Branch number
- Button: "← Nueva Búsqueda" (returns to Step 2)

**Business Rule:** NO progression allowed. Must search different customer.

---

#### Step 3b: Cliente Disponible (If no active loan)
**Screen Type:** Success/Confirmation

**UI Elements:**
- Green confirmation banner (`#10b981`)
- Message: "Cliente disponible para nuevo crédito"
- Verification checkmark: "✓ Sin créditos activos"
- Button: "Iniciar Solicitud →" (proceeds to Step 4)

**Business Rule:** Enable credit application flow.

---

#### Step 4: Datos Generales (Credit Application - Part 1)
- Collect customer data (personal info)
- **REQUIRED**: Capture date of birth (fecha de nacimiento) to calculate age
- Fields: Número de Identidad, Nombre Completo, Género, Fecha de Nacimiento, Dirección, Ciudad, Departamento, Teléfono
- Button: "Siguiente"

---

#### Step 5: Fotografías (Credit Application - Part 2)
- Upload ID photos (front/back) and facial verification to S3
- Verification method selector (SMS/WhatsApp)
- Email (optional)
- Button: "Siguiente"

---

#### Step 6: Datos Laborales (Credit Application - Part 3)
- Employment status selector
- Salary range selector
- Button: "Siguiente"

---

#### Step 7: Resumen Solicitud (Credit Application - Part 4)
- Read-only summary of all entered data
- Button: "Enviar Solicitud"

**Next:** Submit for approval → Step 8a or 8b

---

#### Step 8a: No Aprobado (Application Rejected)
**UI Elements:**
- Red message (`#ef4444`): "No Aprobado"
- Rejection reason display
- Button: "Nueva Búsqueda" (returns to Step 2)

---

#### Step 8b: Aprobado (Application Approved)
**UI Elements:**
- Green message (`#10b981`): "Aprobado"
- Display: Application number (format: `APP-000001`)
- **IMPORTANT:** Do NOT display approved amount
- Button: "Continuar" (proceeds to Step 9)

**Backend:** Generate application number, store approved amount (backend only)

---

#### Step 9: Recuperar Solicitud
**UI Elements:**
- Input field: "Ingrese Número de Solicitud aprobada"
- Button: "Ingresar"
- Upon entry, display (read-only): Nombre, Identidad, Teléfono, Correo, Foto
- **CRITICAL:** Do NOT display "Monto Aprobado" on frontend
- Button: "Proceder" (to Step 10)

---

#### Step 10: Catálogo Teléfonos (Device Selection)
**UI Elements:**
- Visual grid of phone models with prices
- Fields appear when model selected: IMEI, Color
- Button: "Siguiente" (to Step 11)

**Phone Filtering Logic (Age-Based):**
- Phones are filtered by **financed amount** (price - down payment), NOT by raw price
- Max phone price = `max_financing / (1 - min_down_payment_percentage)`
- **Age 21-49**: Max financed L. 3,500, min DP 30% → max phone price L. 5,000
- **Age 50-60**: Max financed L. 3,000, min DP 40% → max phone price L. 5,000

**Note:** NO accessories feature. Phone only.

---

#### Step 11: Confirmación (Purchase Summary)
**UI Elements:**
- Display: Selected phone model, Total price (phone only)
- Button: "Siguiente" (to Step 12)

---

#### Step 12: Calculadora (Payment Calculator)
**UI Elements:**
- Summary: Phone model, Total price
- Down payment selector: 30%, 40%, 50% (radio buttons)
- Installment term selector: 6, 8, 10, 12 bi-weekly periods
- Dynamic display: "Cuota Quincenal: L. ----"
- Button: "Generar Crédito" (to Step 13)

**Calculation:** Based on phone price ONLY (no accessories)

---

**⚠️ TEMPORARY: Payment Calculator Reference Data (DELETE AFTER PROJECT COMPLETION)**

**Interest Rate Table (Bi-weekly Rates):**

| Down Payment (Prima) | 6 Payments | 8 Payments | 10 Payments | 12 Payments |
|---------------------|------------|------------|-------------|-------------|
| 30% | 14.0% | 13.5% | 13.0% | 12.5% |
| 40% | 13.0% | 12.5% | 12.0% | 11.5% |
| 50% | 12.0% | 11.5% | 11.0% | 10.5% |

**Age and Credit Restrictions:**

- **Credit available for ages:** 21 - 60 years
- **Age-based limits:**
  - **50-60 years:** Only 40% and 50% down payment options
  - **21-49 years:** All down payment options (30%, 40%, 50%)

**Calculation Example:**
```
Phone Price:           L. 3,500
Down Payment (30%):    L. 1,050
Financed Amount:       L. 2,450
Bi-weekly Rate:        0.125 (12.5% for 30% down, 12 payments)
Number of Payments:    12 bi-weekly periods
Bi-weekly Payment:     L. 404.73
```

**Formula:**
```ruby
financed_amount = phone_price - (phone_price * down_payment_percentage)
bi_weekly_rate = interest_rate_from_table[down_payment][periods] / 100
payment = financed_amount * (bi_weekly_rate * (1 + bi_weekly_rate) ** periods) /
          ((1 + bi_weekly_rate) ** periods - 1)
```

**Implementation Notes:**
- Use interest rates from table above (NOT annual_rate / 26)
- Validate customer age from date_of_birth
- Enforce age-based restrictions on down payment and max financed amount:
  - **50-60 years**: Max financed L. 3,000 (only 40% and 50% DP)
  - **21-49 years**: Max financed L. 3,500 (all DP options)
- Available payment terms: 6, 8, 10, 12 bi-weekly periods (note: 10 was added)
- Store bi_weekly_rate used in loan record for audit trail

---

#### Step 13: Contrato (Contract Display)
**UI Elements:**
- Document viewer with complete contract
- All customer and loan data pre-filled
- Button: "Aceptar" (to Step 14)

---

#### Step 14: Firma Digital (Digital Signature)
**UI Elements:**
- Touch-sensitive signature area
- Button: "Guardar" (to Step 15)
- Save signature to S3

---

#### Step 15: Crédito Aplicado (Success Confirmation)
**UI Elements:**
- Large success message (green `#10b981`): "¡Crédito Aplicado! Felicidades. Estás a unos pasos de disfrutar de nueva compra."
- Two action buttons:
  1. "Descargar Contrato"
  2. "Proceder a Configuración de Teléfono" (to Step 16)

---

#### Step 16: Código QR (QR Generation)
**UI Elements:**
- Large QR code display (BluePrint for MDM)
- Instruction: "Escanee este QR con el teléfono del cliente para iniciar la configuración."
- MDM configuration mechanism

---

#### Step 17: Checklist Final (Device Configuration)
**UI Elements:**
- Title: "Verificación de Configuración del Cliente"
- Manual checklist:
  - [ ] BluePrint escaneado y configuración realizada
  - [ ] Aplicación MDM instalada y confirmada
  - [ ] Aplicación MoviCuotas instalada y Log-in realizado
- Button: "Finalizar Proceso de Venta" (returns to Step 2)

---

#### Step 18: Tracking de Préstamo (Loan Tracking Dashboard)
**Accessible from:** Main navigation menu

**UI Elements:**
- Loan status display
- Installment schedule with status
- Payment history
- Remaining balance
- Next payment due date

---

### Dashboard (Accessible from Navigation Menu)

**Access:** From navigation menu on main screen (Step 2)

**Not the main screen** - vendors start at Customer Search (Step 2), not Dashboard.

**UI Elements:**
- Total customers (active/suspended/blocked)
- Total devices assigned
- Active loans count and total value
- Payments collected this month
- Overdue installments count and value
- Recent payments list (last 10)
- Upcoming due dates (next 7 days)
- Quick actions (can initiate "Nueva Búsqueda")

**Navigation:**
- Returns to Step 2 (Buscar Cliente) when starting new sale

---
