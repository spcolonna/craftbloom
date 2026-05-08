abstract final class Validators {
  static String? required(String? value, [String field = 'Este campo']) {
    if (value == null || value.trim().isEmpty) return '$field es obligatorio.';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'El email es obligatorio.';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value.trim())) return 'Ingresá un email válido.';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'El teléfono es obligatorio.';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return 'Ingresá un teléfono válido.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria.';
    if (value.length < 6) return 'La contraseña debe tener al menos 6 caracteres.';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirmá tu contraseña.';
    if (value != password) return 'Las contraseñas no coinciden.';
    return null;
  }

  static String? orderCode(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresá tu código de pedido.';
    final code = value.trim().toUpperCase();
    if (code.length > 12) return 'El código no puede superar los 12 caracteres.';
    if (!RegExp(r'^CB-[A-Z0-9]{6}$').hasMatch(code)) {
      return 'Formato inválido. Ejemplo: CB-A4F7K2';
    }
    return null;
  }

  static String? minLength(String? value, int min, [String field = 'Este campo']) {
    if (value == null || value.trim().length < min) {
      return '$field debe tener al menos $min caracteres.';
    }
    return null;
  }
}
