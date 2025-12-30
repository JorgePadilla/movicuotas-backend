## Project Structure

```
movicuotas-backend/
├── app/
│   ├── components/         # ViewComponent 4 components
│   │   ├── shared/        # Reusable UI components
│   │   ├── admin/         # Admin-specific components
│   │   ├── vendor/        # Vendor-specific components
│   │   └── reports/       # Report components
│   ├── controllers/
│   │   ├── admin/         # Admin web interface
│   │   ├── vendor/        # Vendor web interface (10-step workflow)
│   │   └── api/v1/        # Mobile app API
│   ├── models/
│   │   ├── customer.rb
│   │   ├── device.rb
│   │   ├── loan.rb
│   │   ├── installment.rb
│   │   ├── payment.rb
│   │   ├── notification.rb
│   │   ├── credit_application.rb
│   │   ├── phone_model.rb
│   │   ├── contract.rb
│   │   └── mdm_blueprint.rb
│   ├── policies/          # Pundit authorization
│   ├── services/          # Business logic
│   │   ├── loan_calculator_service.rb
│   │   ├── payment_processor_service.rb
│   │   ├── notification_service.rb
│   │   ├── credit_approval_service.rb
│   │   ├── contract_generator_service.rb
│   │   └── mdm_service.rb
│   └── jobs/              # Solid Queue background jobs
├── db/
│   ├── migrate/
│   └── seeds.rb
└── test/                  # Minitest tests
```

