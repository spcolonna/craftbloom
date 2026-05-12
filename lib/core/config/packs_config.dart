/// Configuración de los packs de Guidaí Bilú.
///
/// Las imágenes se ubican en assets/images/ con el nombre pack_N.jpg
/// (pack_1.jpg = cumpleaños, pack_2.jpg = baby shower, …, pack_6.jpg = custom).
///
/// Usá [PacksConfig.all] para mostrar los packs en la tienda.
/// Para ajustar precio o contenido editá únicamente este archivo.

abstract final class PacksConfig {
  static const all = <PackEntry>[
    PackEntry(
      id: 'cumpleanos',
      name: 'Pack Cumpleaños',
      occasion: 'Cumpleaños',
      imagePath: 'assets/images/pack_1.jpg',
      badge: 'Más vendido',
      basePrice: 1500,
      priceUnit: 'por pack',
      description:
          'Decoración completa y personalizada para cumpleaños. '
          'Todos los elementos son cortados en vinilo adhesivo o cartulina '
          'de alta gramaje con la Silhouette Cameo 5 Alpha.',
      items: [
        'Cartel "Feliz Cumpleaños" en vinilo adhesivo (formato A4)',
        '6 toppers para torta o cupcakes en cartulina plastificada',
        '10 etiquetas circulares para candy bar con nombre y edad',
        'Guirnalda de banderines decorativos en papel 200 g',
        '20 stickers temáticos en vinilo resistente al agua',
        '8 tarjetitas de agradecimiento personalizadas (5×7 cm)',
      ],
      addOns: [
        'Globos de vinilo con nombre (+\$U 300)',
        'Caja sorpresa de cartulina (+\$U 400)',
        'Stickers holográficos en lugar de vinilo mate (+\$U 200)',
      ],
    ),

    PackEntry(
      id: 'baby_shower',
      name: 'Pack Baby Shower',
      occasion: 'Baby Shower',
      imagePath: 'assets/images/pack_2.jpg',
      basePrice: 1600,
      priceUnit: 'por pack',
      description:
          'Decoración dulce para dar la bienvenida al bebé. '
          'Diseños tiernos cortados en cartulina y vinilo con paleta '
          'personalizable según si es nena, nene o sorpresa.',
      items: [
        'Cartel principal con nombre del bebé o "Baby Shower" en vinilo',
        '8 toppers de cupcake (ositos, estrellas, lunitas)',
        '15 etiquetas para candy bar y souvenirs',
        'Guirnalda con letras del nombre del bebé en papel 200 g',
        '20 stickers de vinilo (chupetes, biberones, zapatitos)',
        '8 tarjetitas de agradecimiento personalizadas',
        'Marco decorativo de cartulina para foto (15×20 cm)',
      ],
      addOns: [
        'Caja para souvenir de cartulina x10 (+\$U 500)',
        'Banner "Es nena/nene" en vinilo (+\$U 350)',
        'Paleta de colores a elección sin cargo',
      ],
    ),

    PackEntry(
      id: 'stickers',
      name: 'Pack Stickers',
      occasion: 'Stickers',
      imagePath: 'assets/images/pack_3.jpg',
      basePrice: 800,
      priceUnit: 'por pack de 50',
      description:
          'Stickers de vinilo de alta calidad cortados con precisión por '
          'la Silhouette Cameo 5 Alpha. Resistentes al agua y al sol. '
          'Ideales para personalizar notebooks, agendas, termos, laptops y regalos.',
      items: [
        '50 stickers en vinilo adhesivo (aprox. 5×5 cm c/u)',
        'Material disponible: vinilo mate, brillante, transparente u holográfico',
        'Diseños a elección: frases, personajes, flores, geométricos, íconos',
        'Corte a contorno con precisión milimétrica',
        'Sin exceso de vinilo alrededor (kiss-cut o die-cut a elección)',
      ],
      addOns: [
        'Vinilo holográfico en lugar de mate (+\$U 150)',
        'Tarjeta de presentación personalizada para regalo (+\$U 100)',
        'Sobre kraft para packaging (+\$U 80)',
      ],
    ),

    PackEntry(
      id: 'valentin',
      name: 'Pack San Valentín',
      occasion: 'San Valentín',
      imagePath: 'assets/images/pack_4.jpg',
      basePrice: 1200,
      priceUnit: 'por pack',
      description:
          'El detalle perfecto para sorprender el 14 de febrero o en cualquier '
          'celebración romántica. Piezas únicas cortadas en vinilo y cartulina '
          'con frases y nombres personalizados.',
      items: [
        'Cartel romántico con nombre o frase en vinilo adhesivo (A4)',
        '6 tarjetas de amor en cartulina con ventana corazón cortada',
        '20 stickers de corazones y frases en vinilo',
        'Confetti de corazones en papel para decorar mesa (aprox. 100 piezas)',
        '8 etiquetas para cajita de chocolates o regalo',
        'Sobre decorativo de cartulina con ventana corazón (C6)',
      ],
      addOns: [
        'Caja de regalo de cartulina con tapa y lazo (+\$U 350)',
        'Stickers holográficos (+\$U 150)',
        'Frase personalizada sin cargo',
      ],
    ),

    PackEntry(
      id: 'eventos',
      name: 'Pack Eventos',
      occasion: 'Eventos',
      imagePath: 'assets/images/pack_5.jpg',
      badge: 'Top en eventos',
      basePrice: 2200,
      priceUnit: 'por pack',
      description:
          'Decoración completa para fiestas, casamientos, graduaciones, '
          '15 años, comuniones y cualquier evento que merezca ser recordado. '
          'Producción en vinilo y cartulina premium.',
      items: [
        'Cartel principal del evento en vinilo (nombre, fecha, lugar)',
        '10 toppers temáticos en cartulina 300 g',
        '20 etiquetas personalizadas para mesa de dulces',
        '2 guirnaldas de banderines decorativos en papel 200 g',
        '30 stickers de vinilo para souvenir y decoración de mesa',
        '10 tarjetas de lugar / nombre para mesa de invitados',
        'Tablero de bienvenida en cartulina gruesa (formato A3)',
      ],
      addOns: [
        'Cajas de souvenir x10 (+\$U 600)',
        'Señalética de dirección al salón (+\$U 300)',
        'Menú impreso + corte de cartulina x10 (+\$U 500)',
      ],
    ),

    PackEntry(
      id: 'custom',
      name: 'Pack Personalizado',
      occasion: 'Personalizado',
      imagePath: 'assets/images/pack_6.jpg',
      basePrice: null,
      priceUnit: 'a convenir',
      description:
          '¿Tenés una idea en mente? Diseñamos y producimos exactamente '
          'lo que necesitás. La Silhouette Cameo 5 Alpha puede cortar '
          'vinilo, cartulina, papel kraft, goma eva, tela y más. '
          'Sin limitaciones de temática ni cantidad.',
      items: [
        'Temática y paleta de colores completamente a elección',
        'Stickers, toppers, etiquetas, carteles o lo que necesitás',
        'Materiales disponibles: vinilo mate, brillante, holográfico, transparente, kraft',
        'Revisión de diseño digital incluida antes de producir',
        'Asesoramiento por WhatsApp o Instagram sin cargo',
        'Precio según detalle del pedido (consultá sin compromiso)',
      ],
      addOns: [],
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Modelo de dato
// ─────────────────────────────────────────────────────────────────────────────

class PackEntry {
  final String id;
  final String name;
  final String occasion;
  final String description;
  final String imagePath;
  final List<String> items;
  final List<String> addOns;

  /// Precio base en UYU. `null` significa "a convenir".
  final double? basePrice;
  final String priceUnit;

  /// Etiqueta opcional que se muestra en la tarjeta, ej. "Más vendido".
  final String? badge;

  const PackEntry({
    required this.id,
    required this.name,
    required this.occasion,
    required this.description,
    required this.imagePath,
    required this.items,
    this.addOns = const [],
    this.basePrice,
    this.priceUnit = 'por pack',
    this.badge,
  });

  /// Convierte a Map para guardar en Firestore.
  Map<String, dynamic> toFirestoreMap() => {
    'name':        name,
    'description': description,
    'occasion':    occasion,
    'items':       items,
    'price':       basePrice ?? 0.0,
    'priceUnit':   priceUnit,
    'isActive':    true,
    'viewCount':   0,
    'imageUrls':   [imagePath],
    'tags':        [occasion.toLowerCase()],
  };
}
