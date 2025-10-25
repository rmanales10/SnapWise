# EmailJS Setup Guide for SnapWise

This guide will help you set up EmailJS to send emails from your Flutter app using Gmail SMTP.

## Step 1: Create EmailJS Account

1. Go to [EmailJS Dashboard](https://dashboard.emailjs.com/)
2. Sign up for a free account
3. Verify your email address

## Step 2: Create Gmail Service

1. In the EmailJS dashboard, go to **Email Services**
2. Click **Add New Service**
3. Select **Gmail** as the service provider
4. Connect your Gmail account (snapwiseofficial25@gmail.com)
5. Note down the **Service ID** (e.g., `service_xxxxxxx`)

## Step 3: Create Email Template

1. Go to **Email Templates**
2. Click **Create New Template**
3. Use this template content:

### Template Subject:
```
Feedback from {{from_name}} - {{purpose}}
```

### Template Content Options:

#### Option 1: Minimal Template (1,539 characters - Recommended)
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>SnapWise Feedback</title>
</head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 20px;">
    <div style="max-width: 600px; margin: 0 auto;">
        <h2 style="color: #2E2E4F; border-bottom: 2px solid #2E2E4F; padding-bottom: 10px;">
            📧 New Feedback from SnapWise App
        </h2>
        
        <div style="background-color: #f8f9fa; padding: 15px; border-radius: 8px; margin: 15px 0;">
            <h3 style="color: #2E2E4F; margin-top: 0;">📋 Feedback Details</h3>
            <p><strong>👤 Name:</strong> {{from_name}}</p>
            <p><strong>📧 Email:</strong> {{from_email}}</p>
            <p><strong>🎯 Purpose:</strong> {{purpose}}</p>
            <p><strong>⭐ Rating:</strong> <span style="color: #ffa500; font-weight: bold;">{{rating}}/5</span></p>
        </div>
        
        <div style="background-color: #e8f4fd; padding: 15px; border-radius: 8px; margin: 15px 0;">
            <h3 style="color: #2E2E4F; margin-top: 0;">💬 Comment</h3>
            <div style="white-space: pre-wrap;">{{comment}}</div>
        </div>
        
        <div style="color: #666; font-size: 12px; text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd;">
            This email was sent from the SnapWise feedback form.<br>
            Reply directly to this email to respond to the user.
        </div>
    </div>
</body>
</html>
```

#### Option 2: Ultra-Minimal Template (844 characters - Maximum Compatibility)
```html
<h2 style="color: #2E2E4F;">📧 New Feedback from SnapWise App</h2>

<div style="background-color: #f8f9fa; padding: 15px; border-radius: 8px; margin: 15px 0;">
    <h3 style="color: #2E2E4F;">📋 Feedback Details</h3>
    <p><strong>Name:</strong> {{from_name}}</p>
    <p><strong>Email:</strong> {{from_email}}</p>
    <p><strong>Purpose:</strong> {{purpose}}</p>
    <p><strong>Rating:</strong> {{rating}}/5</p>
</div>

<div style="background-color: #e8f4fd; padding: 15px; border-radius: 8px; margin: 15px 0;">
    <h3 style="color: #2E2E4F;">💬 Comment</h3>
    <div style="white-space: pre-wrap;">{{comment}}</div>
</div>

<div style="color: #666; font-size: 12px; text-align: center; margin-top: 20px; padding-top: 15px; border-top: 1px solid #ddd;">
    This email was sent from the SnapWise feedback form.
</div>
```

4. Save the template and note down the **Template ID** (e.g., `template_xxxxxxx`)

## Step 4: Get API Keys

1. Go to **Account** > **General**
2. Note down your **User ID** (e.g., `user_xxxxxxx`)
3. Go to **Account** > **API Keys**
4. Note down your **Public Key** (e.g., `your_public_key_here`)

## Step 5: Update Configuration

1. Open `lib/services/emailjs_config.dart`
2. Replace the placeholder values with your actual credentials:

```dart
class EmailJSConfig {
  // Replace these with your actual EmailJS credentials
  static const String serviceId = 'service_your_actual_service_id';
  static const String templateId = 'template_your_actual_template_id';
  static const String publicKey = 'your_actual_public_key';
  static const String userId = 'your_actual_user_id';
  
  // ... rest of the configuration
}
```

## Step 6: Test the Setup

1. Run your Flutter app
2. Go to the feedback form
3. Fill out the form and submit
4. Check your Gmail inbox for the feedback email
5. Check the console logs for any errors

## Troubleshooting

### Common Issues:

1. **"EmailJS not configured"** - Make sure you've updated all the credentials in `emailjs_config.dart`

2. **"EmailJS failed with status: 400"** - Check that your template parameters match what you're sending

3. **"EmailJS failed with status: 401"** - Verify your User ID and Public Key are correct

4. **"EmailJS failed with status: 403"** - Check that your Gmail service is properly connected

### Debug Steps:

1. Check the console logs for detailed error messages
2. Verify all credentials are correct in the config file
3. Test the template in EmailJS dashboard
4. Check that your Gmail account has "Less secure app access" enabled (if required)

## Security Notes

- Never commit your actual EmailJS credentials to version control
- Consider using environment variables for production
- The public key is safe to use in frontend code
- EmailJS handles the SMTP connection securely

## Fallback System

The app includes a fallback system that will use your existing PHP API if EmailJS fails, ensuring your feedback system always works.

## Support

If you encounter issues:
1. Check the EmailJS documentation: https://www.emailjs.com/docs/
2. Verify your Gmail service connection
3. Test with a simple template first
4. Check the browser console for detailed error messages
