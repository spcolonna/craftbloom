import 'package:flutter/material.dart';
import 'package:craftbloom/core/constants/app_colors.dart';

// ─────────────────────────────────────────────
//  ARCHIVO MAESTRO DE CONFIGURACIÓN
//  Completar los valores marcados con ← COMPLETAR
// ─────────────────────────────────────────────

abstract final class AppConfig {
  // ── Información del negocio ──────────────────
  static const String businessName = 'CraftBloom';
  static const String tagline = 'Diseños que te enamoran';
  static const String contactEmail = 'hola@craftbloom.com'; // ← COMPLETAR
  static const String whatsappNumber = '+598XXXXXXXXX';     // ← COMPLETAR (formato internacional)
  static const String instagramHandle = '@craftbloom';      // ← COMPLETAR
  static const String logoAsset = 'assets/images/logo.png'; // ← Agregar logo al proyecto

  // ── URLs de redes sociales ───────────────────
  static const String instagramUrl = 'https://instagram.com/craftbloom';   // ← COMPLETAR
  static const String whatsappUrl = 'https://wa.me/598XXXXXXXXX';          // ← COMPLETAR
  static const String facebookUrl = '';                                     // ← COMPLETAR (o dejar vacío)
  static const String tiktokUrl = '';                                       // ← COMPLETAR (o dejar vacío)

  // ── Configuración de pedidos ─────────────────
  static const String orderCodePrefix = 'CB';
  static const int orderCodeRandomChars = 6;
  static const int maxOrderCodeLength = 12;
  static const int maxImagesPerOrder = 5;
  static const double maxImageSizeMB = 10;

  // ── Moneda ───────────────────────────────────
  static const String currencySymbol = r'$U';
  static const String currencyCode = 'UYU';
  static const String locale = 'es_UY';

  // ── Opciones de entrega ──────────────────────
  static const String pickupAddress = 'Montevideo, Uruguay'; // ← COMPLETAR dirección exacta de retiro

  // ── Categorías de productos (precargadas) ────
  static const List<String> productCategories = [
    'Stickers',
    'Packs de Cumpleaños',
    'Etiquetas',
    'Decoración',
    'Regalos',
    'Baby Shower',
    'Eventos',
    'Personalizado',
  ];

  // ── Ocasiones para paquetes (precargadas) ────
  static const List<String> packageOccasions = [
    'Cumpleaños',
    'Baby Shower',
    'Casamiento',
    'Bautismo',
    'Comunión',
    'Graduación',
    'Empresarial',
    'Regalo',
    'Navidad',
    'Otro',
  ];

  // ── Métodos de pago disponibles ──────────────
  static const List<Map<String, String>> paymentMethods = [
    {
      'id': 'transfer',
      'label': 'Transferencia bancaria',
      'icon': 'bank',
      'description': 'Transferí al número de cuenta y envianos el comprobante.',
    },
    {
      'id': 'cash',
      'label': 'Efectivo al momento de la entrega',
      'icon': 'cash',
      'description': 'Pagás en efectivo cuando retirás o recibís tu pedido.',
    },
    {
      'id': 'mercadopago',
      'label': 'MercadoPago',
      'icon': 'mp',
      'description': 'Pagá online con tarjeta, débito o saldo MP.',
    },
  ];

  // ── Datos bancarios para transferencia ──────
  static const String bankName = 'BROU';                              // ← COMPLETAR
  static const String bankAccountHolder = 'Nombre Apellido';          // ← COMPLETAR
  static const String bankAccountType = 'Caja de ahorro en \$U';     // ← COMPLETAR
  static const String bankAccountNumber = '000-XXXXXXXX/XX';          // ← COMPLETAR
  static const String bankAlias = '';                                  // ← COMPLETAR (si aplica)

  // ── Emails de administradores ─────────────────
  static const List<String> adminEmails = [
    'admin@craftbloom.com', // ← COMPLETAR
  ];

  // ── Configuración de estados de pedido ───────
  static const Map<String, OrderStatusConfig> orderStatusConfig = {
    'pending': OrderStatusConfig(
      label: 'Pendiente',
      color: AppColors.statusPending,
      icon: Icons.schedule_outlined,
      description: 'Tu pedido fue enviado y está esperando revisión.',
    ),
    'received': OrderStatusConfig(
      label: 'Recibido',
      color: AppColors.statusReceived,
      icon: Icons.inbox_outlined,
      description: 'Recibimos tu pedido y lo estamos revisando.',
    ),
    'accepted': OrderStatusConfig(
      label: 'Aceptado',
      color: AppColors.statusAccepted,
      icon: Icons.check_circle_outline,
      description: 'Tu pedido fue aceptado. ¡Manos a la obra!',
    ),
    'rejected': OrderStatusConfig(
      label: 'Rechazado',
      color: AppColors.statusRejected,
      icon: Icons.cancel_outlined,
      description: 'Lo sentimos, no pudimos aceptar tu pedido.',
    ),
    'awaiting_payment': OrderStatusConfig(
      label: 'A la espera de pago',
      color: AppColors.statusAwaitingPayment,
      icon: Icons.payment_outlined,
      description: 'Tu pedido está esperando la confirmación del pago.',
    ),
    'processing': OrderStatusConfig(
      label: 'Procesándose',
      color: AppColors.statusProcessing,
      icon: Icons.precision_manufacturing_outlined,
      description: 'Tu pedido está siendo producido.',
    ),
    'paused': OrderStatusConfig(
      label: 'Pausado',
      color: AppColors.statusPaused,
      icon: Icons.pause_circle_outline,
      description: 'La producción de tu pedido está pausada temporalmente.',
    ),
    'ready': OrderStatusConfig(
      label: 'Listo',
      color: AppColors.statusReady,
      icon: Icons.inventory_2_outlined,
      description: '¡Tu pedido está listo! Te avisamos cómo continuar.',
    ),
    'shipped': OrderStatusConfig(
      label: 'Enviado',
      color: AppColors.statusShipped,
      icon: Icons.local_shipping_outlined,
      description: 'Tu pedido está en camino.',
    ),
    'completed': OrderStatusConfig(
      label: 'Completado',
      color: AppColors.statusCompleted,
      icon: Icons.done_all,
      description: '¡Pedido entregado! Gracias por elegirnos.',
    ),
    'cancelled': OrderStatusConfig(
      label: 'Cancelado',
      color: AppColors.statusCancelled,
      icon: Icons.block,
      description: 'Este pedido fue cancelado.',
    ),
  };

  // ── Paquetes temáticos de ejemplo (precargados) ──
  static const List<Map<String, dynamic>> samplePackages = [
    {
      'name': 'Pack Cumpleaños Básico',
      'description': 'Ideal para celebrar con estilo. Incluye globos personalizados, stickers temáticos y etiquetas.',
      'occasion': 'Cumpleaños',
      'price': 850.0,
      'priceUnit': 'por pack',
      'items': [
        '20 stickers temáticos',
        '10 etiquetas personalizadas',
        '1 número/nombre en vinilo',
      ],
      'isActive': true,
    },
    {
      'name': 'Pack Baby Shower',
      'description': 'Decoración especial para la llegada del bebé. Tierna y delicada.',
      'occasion': 'Baby Shower',
      'price': 1200.0,
      'priceUnit': 'por pack',
      'items': [
        '30 stickers para recuerdos',
        '20 etiquetas para souvenirs',
        '1 cartel personalizado',
        '10 stickers de nombre',
      ],
      'isActive': true,
    },
    {
      'name': 'Pack Stickers x50',
      'description': '50 stickers a tu elección. Diseño personalizado o de nuestra colección.',
      'occasion': 'Stickers',
      'price': 500.0,
      'priceUnit': 'por pack de 50',
      'items': [
        '50 stickers en vinilo de alta calidad',
        'Diseño personalizado incluido',
        'Corte preciso con Cameo 5',
      ],
      'isActive': true,
    },
    {
      'name': 'Pack Casamiento Premium',
      'description': 'Todo lo necesario para decorar tu gran día con un toque único y personalizado.',
      'occasion': 'Casamiento',
      'price': 3500.0,
      'priceUnit': 'por pack',
      'items': [
        '50 etiquetas para recuerdos',
        '30 stickers personalizados',
        '2 carteles nombres novios',
        '1 cartel mesa principal',
        '20 stickers para sobres',
      ],
      'isActive': true,
    },
  ];

  // ── Configuración de analytics ────────────────
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = false;

  // ── Configuración de Firebase (se genera con flutterfire) ──
  // Ver firebase_options.dart en la raíz del proyecto
}

// ── Data classes de configuración ────────────
@immutable
class OrderStatusConfig {
  final String label;
  final Color color;
  final IconData icon;
  final String description;

  const OrderStatusConfig({
    required this.label,
    required this.color,
    required this.icon,
    required this.description,
  });
}
