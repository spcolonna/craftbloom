/// Productos de muestra para sembrar en Firestore desde el panel admin.
/// Editá este archivo para agregar, quitar o modificar el catálogo inicial.

abstract final class ProductsConfig {
  static const all = <ProductEntry>[
    ProductEntry(
      id: 'stickers_vinilo',
      name: 'Stickers de Vinilo',
      category: 'Stickers',
      description:
          'Stickers cortados con precisión milimétrica en vinilo adhesivo de alta calidad. '
          'Resistentes al agua, al sol y al roce. Ideales para notebooks, termos, laptops, '
          'mochilas y regalos. Disponibles en vinilo mate, brillante, transparente u holográfico.',
      price: 350,
      priceUnit: 'por 10 unidades',
      tags: ['stickers', 'vinilo', 'personalizado'],
    ),
    ProductEntry(
      id: 'etiquetas_tarro',
      name: 'Etiquetas para Tarros',
      category: 'Etiquetas',
      description:
          'Etiquetas adhesivas cortadas a medida para tarros de mermelada, especias, '
          'conservas y cosmética artesanal. Diseño personalizado con nombre, logo o ilustración. '
          'Material: vinilo mate resistente a la humedad.',
      price: 280,
      priceUnit: 'por 12 unidades',
      tags: ['etiquetas', 'tarros', 'cocina'],
    ),
    ProductEntry(
      id: 'tags_regalo',
      name: 'Tags para Regalos',
      category: 'Etiquetas',
      description:
          'Tarjetitas y tags en cartulina premium de 300 g cortadas con formas especiales: '
          'corazón, estrella, círculo, rectángulo con esquinas redondeadas. '
          'Ideales para paquetes de regalo, souvenirs y detalles de casamiento o baby shower.',
      price: 220,
      priceUnit: 'por 20 unidades',
      tags: ['tags', 'regalo', 'cartulina'],
    ),
    ProductEntry(
      id: 'letras_decorativas',
      name: 'Letras Decorativas',
      category: 'Decoración',
      description:
          'Letras y números en vinilo adhesivo para decorar paredes, espejos, vidrios '
          'y muebles. Altura desde 5 cm hasta 30 cm. Disponibles en más de 20 colores '
          'de vinilo mate o brillante. Perfectas para nombres en cuartos infantiles.',
      price: 180,
      priceUnit: 'por letra',
      tags: ['letras', 'decoracion', 'vinilo'],
    ),
    ProductEntry(
      id: 'marcos_foto',
      name: 'Marco Fotográfico Decorativo',
      category: 'Decoración',
      description:
          'Marcos para fotos en cartulina gruesa 300 g con recortes decorativos alrededor. '
          'Tamaño 10×15 cm (foto 9×13). Diseños disponibles: flores, estrellas, geométrico, '
          'corazones. Personalizables con nombre o frase. Incluye soporte trasero.',
      price: 320,
      priceUnit: 'por unidad',
      tags: ['marco', 'foto', 'cartulina', 'decoracion'],
    ),
    ProductEntry(
      id: 'stickers_holo',
      name: 'Stickers Holográficos',
      category: 'Stickers',
      description:
          'Stickers en vinilo holográfico iridiscente que cambian de color con la luz. '
          'Efecto espejo arcoíris único. Resistentes al agua. '
          'Ideales para laptops, agendas, botellas y packaging de emprendimientos.',
      price: 480,
      priceUnit: 'por 10 unidades',
      tags: ['stickers', 'holografico', 'especial'],
    ),
  ];
}

class ProductEntry {
  final String id;
  final String name;
  final String category;
  final String description;
  final double price;
  final String priceUnit;
  final List<String> tags;

  const ProductEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.priceUnit,
    this.tags = const [],
  });

  Map<String, dynamic> toFirestoreMap() => {
    'name':        name,
    'description': description,
    'category':    category,
    'price':       price,
    'priceUnit':   priceUnit,
    'imageUrls':   [],
    'isActive':    true,
    'tags':        tags,
    'viewCount':   0,
  };
}
