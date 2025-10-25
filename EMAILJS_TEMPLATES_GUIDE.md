# EmailJS Templates for SnapWise

This guide provides multiple EmailJS template options, all well under the 50,000 character limit.

## Template Options

### 1. Minimal HTML Template (Recommended)
- **File**: `EMAILJS_TEMPLATE_MINIMAL.html`
- **Characters**: 1,539
- **Features**: Professional design, responsive, SnapWise branding
- **Best for**: Most email clients, good balance of features and size

### 2. Ultra-Minimal HTML Template
- **File**: `EMAILJS_TEMPLATE_ULTRA_MINIMAL.html`
- **Characters**: 844
- **Features**: Maximum compatibility, clean design
- **Best for**: Older email clients, maximum reliability

### 3. Text-Only Template
- **File**: `EMAILJS_TEMPLATE_TEXT.txt`
- **Characters**: 419
- **Features**: Universal compatibility, no HTML
- **Best for**: Basic email clients, maximum compatibility

## Character Count Summary

| Template | Characters | % of Limit | Use Case |
|----------|------------|------------|----------|
| Text Only | 419 | 0.8% | Maximum compatibility |
| Ultra-Minimal | 844 | 1.7% | Older email clients |
| Minimal | 1,539 | 3.1% | Recommended choice |
| **EmailJS Limit** | **50,000** | **100%** | Maximum allowed |

## Template Variables

All templates use these EmailJS variables:
- `{{from_name}}` - User's name
- `{{from_email}}` - User's email
- `{{purpose}}` - Feedback purpose
- `{{rating}}` - Star rating (1-5)
- `{{comment}}` - User's comment

## How to Use

1. **Choose a template** based on your needs
2. **Copy the template content** from the file
3. **Paste into EmailJS** template editor
4. **Set the subject** to: `Feedback from {{from_name}} - {{purpose}}`
5. **Save and get your Template ID**

## Template Features

### Minimal HTML Template
- ✅ Professional SnapWise branding
- ✅ Responsive design
- ✅ Color-coded sections
- ✅ Emoji icons for visual appeal
- ✅ Proper HTML structure
- ✅ Works on all modern email clients

### Ultra-Minimal HTML Template
- ✅ Clean, simple design
- ✅ Maximum email client compatibility
- ✅ SnapWise color scheme
- ✅ Essential information only
- ✅ Fast loading

### Text-Only Template
- ✅ Universal compatibility
- ✅ No HTML rendering issues
- ✅ Works on all email clients
- ✅ Clean, readable format
- ✅ Minimal character usage

## EmailJS Setup

1. Go to [EmailJS Dashboard](https://dashboard.emailjs.com/)
2. Create a new template
3. Set subject: `Feedback from {{from_name}} - {{purpose}}`
4. Copy and paste your chosen template
5. Save and note the Template ID
6. Update `lib/services/emailjs_config.dart` with your Template ID

## Testing

After setting up your template:
1. Use the test widget in your app
2. Send a test email
3. Check your Gmail inbox
4. Verify the formatting looks correct
5. Test with different email clients if needed

## Troubleshooting

### Template Not Working
- Check that all variables are spelled correctly
- Ensure template is saved in EmailJS
- Verify Template ID is correct in config

### Email Formatting Issues
- Try the Ultra-Minimal template
- Use the Text-Only template for maximum compatibility
- Check email client HTML support

### Character Limit Concerns
- All templates are well under the 50,000 limit
- Text template uses only 0.8% of the limit
- Even the largest template uses only 3.1% of the limit

## Customization

You can customize any template by:
- Changing colors to match your brand
- Adding or removing sections
- Modifying the layout
- Adding your logo or additional information

Just make sure to stay under the 50,000 character limit!
