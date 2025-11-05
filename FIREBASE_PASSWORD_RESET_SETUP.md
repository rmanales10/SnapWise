# Firebase Email Setup Guide (Password Reset & Email Verification)

## Issues Addressed
1. Password reset email link not working properly
2. Email verification email not being sent during signup

## Solutions Applied
1. Updated the `ForgotController` to include proper `ActionCodeSettings` configuration for password reset emails
2. Enhanced `RegisterController` to properly send email verification with better error handling

## Firebase Console Configuration Required

### 1. Authorized Domains
Make sure your Firebase auth domain is added to authorized domains:

1. Go to Firebase Console → Authentication → Settings → Authorized domains
2. Ensure these domains are added:
   - `snapwisefinal.firebaseapp.com`
   - `snapwisefinal.web.app`
   - Your custom domain (if any)

### 2. Email Template Configuration

#### Password Reset Template:
1. Go to Firebase Console → Authentication → Templates
2. Click on "Password reset" template
3. You can customize the email template using the HTML template in `FIREBASE_RESET_PASSWORD_TEMPLATE.html`
4. Make sure the placeholders are preserved:
   - `%APP_NAME%` - App name
   - `%EMAIL%` - User's email
   - `%LINK%` - Password reset link

#### Email Verification Template:
1. Go to Firebase Console → Authentication → Templates
2. Click on "Email address verification" template
3. You can customize the email template using the HTML template in `FIREBASE_EMAIL_VERIFICATION_TEMPLATE.html`
4. Make sure the placeholders are preserved:
   - `%APP_NAME%` - App name
   - `%LINK%` - Email verification link

### 3. Email Action URL Configuration
1. Go to Firebase Console → Authentication → Settings → Email action URL
2. Set the action URL to: `https://snapwisefinal.firebaseapp.com/__/auth/action`
3. This allows the reset link to work properly

## Testing

### Test the Password Reset Flow:
1. Enter a valid email address in the forgot password screen
2. Check the email inbox (and spam folder)
3. Click the reset link in the email
4. The link should open in a browser and allow password reset
5. After resetting, you can log in with the new password

### Test the Email Verification Flow:
1. Register a new account with a valid email
2. Check the email inbox (and spam folder) for verification email
3. Click the verification link in the email
4. The link should verify the email address
5. After verification, you can log in to the app

### Common Issues:

#### Email not being sent:
- Check Firebase Console → Authentication → Users to verify the email exists
- Check Firebase Console → Authentication → Usage for any quotas exceeded
- Verify email is not in spam folder
- Check Firebase project billing status

#### Link not working:
- Verify the authorized domains include the Firebase auth domain
- Check that the email action URL is configured correctly
- Ensure the continue URL in ActionCodeSettings matches an authorized domain

#### Error: "invalid-continue-uri" or "unauthorized-continue-uri":
- Add the continue URL to authorized domains in Firebase Console
- The URL should be: `https://snapwisefinal.firebaseapp.com`

## Code Changes Made

### Password Reset (`ForgotController`):
1. **Added ActionCodeSettings** to `sendPasswordResetEmail()`:
   - Configured proper continue URL
   - Set Android package name
   - Disabled app install prompt

2. **Enhanced Error Handling**:
   - Added specific error messages for invalid/unauthorized URLs
   - Better logging for debugging

3. **Improved User Feedback**:
   - Updated success message to remind users to check spam folder
   - More detailed error messages

### Email Verification (`RegisterController`):
1. **Improved Email Verification**:
   - Added try-catch around `sendEmailVerification()` to handle errors gracefully
   - Registration continues even if email verification fails (user can resend later)
   - Better logging for debugging verification email issues

2. **Enhanced User Feedback**:
   - Updated success message to remind users to check spam folder
   - Clear instructions about email verification requirement

## Next Steps

If the issue persists after these changes:

1. Check Firebase Console logs for authentication errors
2. Verify email delivery in Firebase Console → Authentication → Users
3. Test with a different email address
4. Check network connectivity
5. Verify Firebase project is properly configured

