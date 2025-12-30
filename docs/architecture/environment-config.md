## Environment-Specific Behavior

### Development
- Use local storage for ActiveStorage
- FCM notifications logged, not sent
- Seed data includes test customers/loans

### Production
- S3 for file storage
- Real FCM notifications
- Audit logging enabled
- Rate limiting enforced

