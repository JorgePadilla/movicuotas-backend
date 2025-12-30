## Key Vendor Workflow Reminders

When implementing vendor features, remember:

**NAVIGATION:**
1. **Main screen is Step 2 (Customer Search)** - NOT Dashboard
2. **Dashboard is accessible from menu** - Secondary function
3. **Flow**: Login → Search → [Process or Dashboard from menu]

**BUSINESS RULES:**
4. **Step 2 is CRITICAL** - Check active loans across ALL stores/branches system-wide
5. **Block if active loan exists** in ANY store - Display RED (`#ef4444`) alert (Step 3a)
6. **Only ONE active loan** per customer in entire system

**WORKFLOW (18 SCREENS):**
7. **All calculations are bi-weekly** (not monthly)
8. **Down payment options**: Only 30%, 40%, or 50%
9. **Installment options**: Only 6, 8, or 12 bi-weekly periods
10. **NO accessories feature** - Phone price only
11. **Price validation**: Phone price must be <= approved amount

**DATA HANDLING:**
12. **File uploads**: ID photos (front/back), facial verification, contract signature → S3
13. **Application numbers**: Format `APP-000001` (sequential)
14. **Contract numbers**: Format `{branch}-{date}-{sequence}` (e.g., `S01-2025-12-04-000001`)
15. **IMEI validation**: Must be unique across entire system
16. **Digital signatures**: Capture via touch interface, save as image
17. **Date of birth**: Required field to calculate customer age
18. **Payment tracking**: Track every payment and link to specific installments
19. **Hide approved amount**: Do NOT display on frontend after Step 8b (only backend validation)

### UI Color Guidelines for Vendor Workflow

**Step 2 - Customer Search (Main Screen)**:
- Search button → CORPORATE BLUE (`#125282`)
- Navigation menu → CORPORATE BLUE (`#125282`)

**Step 3a - Cliente Bloqueado**:
- Alert banner → RED (`#ef4444`)
- Error message text → RED (`#ef4444`)

**Step 3b - Cliente Disponible**:
- Confirmation banner → GREEN (`#10b981`)
- Success message → GREEN (`#10b981`)

**Step 8a - Application Rejected**:
- Rejection message → RED (`#ef4444`)

**Step 8b - Application Approved**:
- Approval message → GREEN (`#10b981`)

**Step 10 - Phone Catalog**:
- Product cards → PURPLE (`#6366f1`)

**Step 12 - Payment Calculator**:
- Primary buttons → CORPORATE BLUE (`#125282`)
- Calculated amounts → DARK GRAY (`#1f2937`)

**Step 14 - Contract Signature**:
- Signature area border → CORPORATE BLUE (`#125282`)

**Step 15 - Final Confirmation**:
- Success message → GREEN (`#10b981`) large text
- Primary action buttons → CORPORATE BLUE (`#125282`)

---

**Last Updated**: 2025-12-16
**Project Status**: Phase 1 - Setup with Vendor Workflow + Rails 8 Authentication

---

