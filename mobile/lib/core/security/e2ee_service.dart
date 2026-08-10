import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// V10: scaffold de gerenciamento de identidade do dispositivo.
/// NÃO é uma implementação completa de protocolo Signal/Double Ratchet.
/// Em produção, use uma biblioteca criptográfica auditada e um protocolo
/// estabelecido em vez de criar criptografia própria.
class E2eeService {
  static const storage = FlutterSecureStorage();

  Future<String> deviceId() async {
    var id = await storage.read(key: 'device_id');
    if (id != null) return id;

    final rnd = Random.secure();
    id = base64UrlEncode(List<int>.generate(24, (_) => rnd.nextInt(256)));
    await storage.write(key: 'device_id', value: id);
    return id;
  }

  Future<void> savePrivateKeyReference(String value) async {
    await storage.write(key: 'e2ee_private_key_ref', value: value);
  }

  Future<String?> privateKeyReference() {
    return storage.read(key: 'e2ee_private_key_ref');
  }
}
