import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashUtils {
  /// Hashes a password string using SHA-256
  static String hashPassword(String password) {
    var bytes = utf8.encode(password); // data being hashed
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies if a plain text password matches a hash
  static bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }
}
