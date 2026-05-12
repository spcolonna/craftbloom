/// Reviews de muestra para el carrusel de opiniones destacadas.
/// Simulan clientes reales con nombres uruguayos y comentarios auténticos.
/// Editá este archivo para agregar, quitar o modificar las reseñas.

abstract final class ReviewsConfig {
  static const featured = <MockReview>[
    MockReview(
      id: 'r1',
      customerName: 'Valentina Rodríguez',
      rating: 5,
      comment:
          'El pack de cumpleaños de mi hija quedó increíble! Todos los detalles perfectos, '
          'los colores exactos que pedí. Se notó mucho trabajo y dedicación. ¡Ya tengo el del año que viene encargado!',
      occasion: 'Cumpleaños',
    ),
    MockReview(
      id: 'r2',
      customerName: 'Camila Fernández',
      rating: 5,
      comment:
          'Compré los stickers para mi agenda y quedaron buenísimos. '
          'El vinilo es muy buena calidad, ya los tengo hace tres meses y no se despegaron ni decoloraron. Sin dudas vuelvo.',
      occasion: 'Stickers',
    ),
    MockReview(
      id: 'r3',
      customerName: 'Sofía Pereira',
      rating: 5,
      comment:
          'El baby shower de mi hermana fue un éxito total gracias a Guidaí Bilú! '
          'La guirnalda con el nombre del bebé fue lo que más gustó. '
          'Muy rápidas en la entrega y súper atentas por WhatsApp.',
      occasion: 'Baby Shower',
    ),
    MockReview(
      id: 'r4',
      customerName: 'Lucía Martínez',
      rating: 5,
      comment:
          'Hice el pack personalizado para el casamiento de mi amiga y quedé feliz. '
          'Adaptaron todo a los colores de la fiesta y el resultado fue espectacular. '
          'Las etiquetas para la mesa de dulces eran una preciosura.',
      occasion: 'Eventos',
    ),
    MockReview(
      id: 'r5',
      customerName: 'Isabella Gómez',
      rating: 4,
      comment:
          'Muy buen producto y atención. Los toppers de torta quedaron divinos. '
          'El único detalle es que tardó un poquito más de lo esperado, pero valió la pena esperar.',
      occasion: 'Cumpleaños',
    ),
    MockReview(
      id: 'r6',
      customerName: 'Martina Suárez',
      rating: 5,
      comment:
          '¡Hermoso trabajo! Pedí el pack de San Valentín para sorprender a mi pareja '
          'y quedó súper romántico. Las tarjetitas cortadas en corazón son un detalle genial. Muy recomendable.',
      occasion: 'San Valentín',
    ),
    MockReview(
      id: 'r7',
      customerName: 'Florencia Álvarez',
      rating: 5,
      comment:
          'Los stickers holográficos que pedí son una belleza. '
          'Los uso para mi emprendimiento y mis clientas siempre me preguntan dónde los hago. '
          'La calidad del vinilo es notablemente mejor que la de otros lugares.',
      occasion: 'Stickers',
    ),
    MockReview(
      id: 'r8',
      customerName: 'Agustina López',
      rating: 5,
      comment:
          'Decoré el quinceañero de mi sobrina con el pack de eventos y todo el mundo quedó impresionado. '
          'El tablero de bienvenida fue la foto de la noche. Sin dudas los recomiendo a todos.',
      occasion: 'Eventos',
    ),
    MockReview(
      id: 'r9',
      customerName: 'Renata Silva',
      rating: 4,
      comment:
          'Muy buena experiencia. Pedí stickers personalizados con el logo de mi negocio '
          'y quedaron perfectos. El proceso de pedido fue muy fácil y la comunicación excelente.',
      occasion: 'Personalizado',
    ),
    MockReview(
      id: 'r10',
      customerName: 'Julieta Cabrera',
      rating: 5,
      comment:
          'Tercer pedido que hago y siempre quedo contenta. '
          'Esta vez fueron los stickers para los souvenirs del baby shower y son preciosos. '
          'Rápido, prolijo y con mucho amor por el detalle.',
      occasion: 'Baby Shower',
    ),
    MockReview(
      id: 'r11',
      customerName: 'Emilia Núñez',
      rating: 5,
      comment:
          'Compramos el pack de cumpleaños para los 5 años de mi nene y quedamos encantados. '
          'Los banderines y toppers eran exactamente lo que habíamos pedido. ¡Muy recomendables!',
      occasion: 'Cumpleaños',
    ),
    MockReview(
      id: 'r12',
      customerName: 'Catalina Torres',
      rating: 5,
      comment:
          'Encontré Guidaí Bilú por Instagram y fue la mejor decisión. '
          'Me ayudaron a diseñar algo completamente personalizado para mi emprendimiento. '
          'Responden rápido, son muy creativas y el resultado es impecable.',
      occasion: 'Personalizado',
    ),
  ];

  /// Subconjunto de reviews para mostrar en el carrusel de la home.
  static List<MockReview> get carousel => [
    featured[0],  // Valentina — cumpleaños
    featured[2],  // Sofía — baby shower
    featured[6],  // Florencia — stickers holográficos
    featured[3],  // Lucía — casamiento personalizado
    featured[5],  // Martina — San Valentín
    featured[7],  // Agustina — quinceañero
  ];
}

class MockReview {
  final String id;
  final String customerName;
  final int rating;
  final String comment;
  final String occasion;

  const MockReview({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.occasion,
  });
}
