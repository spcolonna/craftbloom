// ══════════════════════════════════════════════════════════════════════════════
// INTEGRACIÓN CON REDES SOCIALES — Guidaí Bilú
// ══════════════════════════════════════════════════════════════════════════════
//
// Este archivo tiene dos funciones:
//  1. Documentar los pasos para obtener las credenciales de Meta/Instagram.
//  2. Definir constantes de configuración del lado del cliente (sin secrets).
//
// ⚠️  NUNCA pongas tokens ni secrets en este archivo ni en ningún lugar del
//     cliente Flutter. Los tokens van SOLO en Firebase Functions como secrets.
//
// ──────────────────────────────────────────────────────────────────────────────
// PASO 1 — Crear una app en Meta Developer Console
// ──────────────────────────────────────────────────────────────────────────────
//  1. Ir a https://developers.facebook.com/
//  2. Clic en "Mis apps" → "Crear app"
//  3. Tipo de app: "Empresa" (Business)
//  4. Agregar el producto "Instagram Graph API" desde el panel de la app
//  5. Anotar los valores de:
//       App ID     → Configuración → Básica → "ID de la app"
//       App Secret → Configuración → Básica → "Clave secreta de la app"
//
// ──────────────────────────────────────────────────────────────────────────────
// PASO 2 — Asegurarse de tener cuenta Instagram de tipo Business o Creator
// ──────────────────────────────────────────────────────────────────────────────
//  1. En la app de Instagram ir a Configuración → Cuenta → Cambiar tipo de cuenta
//     y seleccionar "Cuenta profesional" (Business o Creator).
//  2. Vincular la cuenta de Instagram a una Página de Facebook en
//     Meta Business Suite → Configuración → Cuentas → Cuentas de Instagram.
//
// ──────────────────────────────────────────────────────────────────────────────
// PASO 3 — Generar un token de acceso con los permisos necesarios
// ──────────────────────────────────────────────────────────────────────────────
//  1. Abrir el Explorador de la API Graph:
//     https://developers.facebook.com/tools/explorer/
//  2. Seleccionar tu app y tu Página de Facebook.
//  3. Agregar estos permisos:
//       - instagram_basic
//       - instagram_content_publish
//       - pages_read_engagement
//       - pages_show_list
//  4. Clic en "Generar token de acceso" → autorizar con tu cuenta.
//     Este token dura ~1 hora (token de corta duración).
//
// ──────────────────────────────────────────────────────────────────────────────
// PASO 4 — Convertir a token de larga duración (~60 días)
// ──────────────────────────────────────────────────────────────────────────────
//  Hacer este GET (reemplazar los valores):
//
//    https://graph.facebook.com/v20.0/oauth/access_token
//      ?grant_type=fb_exchange_token
//      &client_id={APP_ID}
//      &client_secret={APP_SECRET}
//      &fb_exchange_token={SHORT_LIVED_TOKEN}
//
//  La respuesta tiene "access_token" → ese es el token de larga duración.
//  Anotar también "expires_in" (segundos) para saber cuándo renovar.
//
// ──────────────────────────────────────────────────────────────────────────────
// PASO 5 — Obtener el ID de la cuenta Instagram Business
// ──────────────────────────────────────────────────────────────────────────────
//  Con el Explorador de la API Graph (o cualquier cliente HTTP):
//
//    GET /me/accounts?access_token={LONG_LIVED_TOKEN}
//    → Obtenés una lista de Páginas. Anotá el "id" de tu página (PAGE_ID)
//      y el "access_token" de la página (PAGE_ACCESS_TOKEN).
//
//    GET /{PAGE_ID}?fields=instagram_business_account&access_token={PAGE_ACCESS_TOKEN}
//    → Obtenés: { "instagram_business_account": { "id": "178414..." } }
//    → Ese número es el IG_ACCOUNT_ID que necesitás.
//
// ──────────────────────────────────────────────────────────────────────────────
// PASO 6 — Configurar los secrets en Firebase Functions
// ──────────────────────────────────────────────────────────────────────────────
//  Ejecutar en la terminal (desde la raíz del proyecto):
//
//    firebase functions:secrets:set IG_ACCESS_TOKEN
//    → Pegar el PAGE_ACCESS_TOKEN de larga duración cuando lo pida.
//       (Nota: usar el token de la PÁGINA, no el del usuario, para que
//        no expire junto con la sesión del usuario.)
//
//    firebase functions:secrets:set IG_ACCOUNT_ID
//    → Pegar el ID numérico de la cuenta Instagram Business.
//
//  Verificar que están guardados:
//    firebase functions:secrets:access IG_ACCESS_TOKEN
//    firebase functions:secrets:access IG_ACCOUNT_ID
//
// ──────────────────────────────────────────────────────────────────────────────
// PASO 7 — (Opcional) Renovar el token antes de que expire
// ──────────────────────────────────────────────────────────────────────────────
//  Los tokens de larga duración duran ~60 días. Para renovar:
//
//    GET https://graph.facebook.com/v20.0/oauth/access_token
//      ?grant_type=fb_exchange_token
//      &client_id={APP_ID}
//      &client_secret={APP_SECRET}
//      &fb_exchange_token={CURRENT_LONG_LIVED_TOKEN}
//
//  Luego actualizar el secret:
//    firebase functions:secrets:set IG_ACCESS_TOKEN
//
// ──────────────────────────────────────────────────────────────────────────────
// PASO 8 — Activar la integración en este archivo
// ──────────────────────────────────────────────────────────────────────────────
//  Una vez que los secrets estén configurados, cambiar instagramEnabled a true.
//
// ══════════════════════════════════════════════════════════════════════════════

abstract final class SocialConfig {
  // Cambiar a true después de completar los pasos de configuración (PASO 6).
  // Cuando es false, la opción "Publicar en Instagram" no aparece en el formulario.
  static const bool instagramEnabled = false; // ← cambiar a true cuando esté listo

  // Versión de la API de Instagram Graph a usar.
  static const String igApiVersion = 'v20.0';
}
