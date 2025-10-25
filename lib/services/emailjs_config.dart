class EmailJSConfig {
  // EmailJS Configuration
  // Get these values from your EmailJS dashboard: https://dashboard.emailjs.com/

  // Service ID - Create a Gmail service in EmailJS dashboard
  static const String serviceId = 'service_roa09pq';

  // Template ID - Create an email template in EmailJS dashboard
  static const String templateId = 'template_d5mnqpl';

  // Public Key - From EmailJS dashboard
  static const String publicKey = 'IH3dH1nhJFr0QhnJn';

  // Private Key - From EmailJS dashboard
  static const String privateKey = 'VgyTQC7u4Z3Hv8YmgCTLO';

  // Recipient email (where feedback will be sent)
  static const String recipientEmail = 'snapwiseofficial25@gmail.com';

  // Validate configuration
  static bool get isConfigured {
    return serviceId.isNotEmpty &&
        templateId.isNotEmpty &&
        publicKey.isNotEmpty &&
        privateKey.isNotEmpty;
  }

  // Get configuration status message
  static String get configurationStatus {
    if (isConfigured) {
      return 'EmailJS is properly configured with official SDK';
    } else {
      return 'EmailJS needs configuration. Please update EmailJSConfig.dart with your credentials';
    }
  }
}
