## Environment-Specific Behavior

### Development
- Use local storage for ActiveStorage
- FCM notifications logged, not sent
- SMS notifications logged, not sent (SmsService mocks responses)
- Seed data includes test customers/loans

### Production
- S3 for file storage
- Real FCM notifications
- Real SMS via AWS SNS
- Audit logging enabled
- Rate limiting enforced

## Environment Variables

### AWS SNS (SMS Notifications)
Required for OTP verification via SMS:

```
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1
```

**Notes:**
- In development/test, SMS messages are logged instead of sent
- AWS IAM user needs `sns:Publish` permission for SMS
- Honduras phone numbers are formatted as `+504XXXXXXXX`

