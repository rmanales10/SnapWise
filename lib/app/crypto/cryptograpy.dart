import 'package:encrypt/encrypt.dart' as encrypt;

/// AES-256 CBC with PKCS7 Padding (exactly like Python version)

// 32-character key (256 bits)
final _key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows!');

// 16-character IV (128 bits)
final _iv = encrypt.IV.fromUtf8('1234567890abcdef');

// AES-CBC + PKCS7 Padding
final _encrypter = encrypt.Encrypter(
  encrypt.AES(
    _key,
    mode: encrypt.AESMode.cbc,
    padding: 'PKCS7',
  ),
);

/// Encrypts a plain text string to Base64 AES ciphertext
String encryptText(String plainText) {
  final encrypted = _encrypter.encrypt(plainText, iv: _iv);
  return encrypted.base64;
}

/// Decrypts a Base64 AES ciphertext to plain text
String decryptText(String encryptedText) {
  try {
    final decrypted = _encrypter.decrypt64(encryptedText, iv: _iv);
    return decrypted;
  } catch (e) {
    return '❌ Decryption failed: $e';
  }
}
