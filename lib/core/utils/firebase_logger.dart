import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loguea errores de Firebase al debug console.
/// Los links de índices faltantes aparecen como texto clickeable en el IDE.
void logFirebaseError(String context, Object error, [StackTrace? stack]) {
  if (error is! FirebaseException) return;

  switch (error.code) {
    case 'permission-denied':
      debugPrint('🔒 [Firestore permission-denied] $context\n   ${error.message}');
    case 'failed-precondition':
      // El mensaje incluye el URL para crear el índice
      debugPrint('📋 [Firestore índice faltante] $context\n   ${error.message}');
    case 'unavailable':
      debugPrint('📡 [Firestore unavailable] $context — sin conexión');
    default:
      debugPrint('🔥 [Firebase ${error.code}] $context\n   ${error.message}');
  }

  // Detectar link de índice aunque venga en otro código de error
  final msg = error.message ?? '';
  if (msg.contains('https://console.firebase.google.com')) {
    final uri = RegExp(r'https://\S+').firstMatch(msg)?.group(0);
    if (uri != null) debugPrint('   👉 Crear índice: $uri');
  }
}

/// Observador de Riverpod — loguea automáticamente cualquier provider
/// que falle con un error de Firebase (incluye StreamProviders de queries).
class FirebaseErrorObserver extends ProviderObserver {
  const FirebaseErrorObserver();

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    final name = provider.name ?? provider.runtimeType.toString();
    logFirebaseError(name, error, stackTrace);
  }
}
