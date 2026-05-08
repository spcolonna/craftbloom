const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { MercadoPagoConfig, Preference, Payment } = require('mercadopago');

initializeApp();
const db = getFirestore();

// ── CONFIGURACIÓN (variables de entorno) ────────────────────────────
// Configurar con: firebase functions:secrets:set MP_ACCESS_TOKEN
// Nunca hardcodear las keys aquí.
const MP_ACCESS_TOKEN = process.env.MP_ACCESS_TOKEN || ''; // ← COMPLETAR

// ── 1. Crear preferencia de MercadoPago ─────────────────────────────
exports.createMPPreference = onCall(async (request) => {
  if (!MP_ACCESS_TOKEN) throw new HttpsError('internal', 'MP no configurado.');

  const { orderId } = request.data;
  if (!orderId) throw new HttpsError('invalid-argument', 'orderId requerido.');

  const orderDoc = await db.collection('orders').doc(orderId).get();
  if (!orderDoc.exists) throw new HttpsError('not-found', 'Pedido no encontrado.');

  const order = orderDoc.data();
  const client = new MercadoPagoConfig({ accessToken: MP_ACCESS_TOKEN });
  const preference = new Preference(client);

  const items = order.items && order.items.length > 0
    ? order.items.map(item => ({
        id: item.productId || orderId,
        title: item.name || 'Producto CraftBloom',
        quantity: item.quantity || 1,
        unit_price: item.unitPrice || (order.totalPrice ? order.totalPrice / order.items.length : 100),
        currency_id: 'UYU',
      }))
    : [{
        id: orderId,
        title: `Pedido ${order.orderCode}`,
        quantity: 1,
        unit_price: order.totalPrice || 100,
        currency_id: 'UYU',
      }];

  const appBaseUrl = process.env.APP_BASE_URL || 'https://craftbloom.com'; // ← COMPLETAR

  const body = {
    items,
    external_reference: orderId,
    notification_url: `https://us-central1-${process.env.GCLOUD_PROJECT}.cloudfunctions.net/mpWebhook`,
    back_urls: {
      success: `${appBaseUrl}/pedido/${order.orderCode}?payment=success`,
      failure: `${appBaseUrl}/pedido/${order.orderCode}?payment=failed`,
      pending: `${appBaseUrl}/pedido/${order.orderCode}?payment=pending`,
    },
    auto_return: 'approved',
  };

  const result = await preference.create({ body });

  await db.collection('orders').doc(orderId).update({ mercadoPagoId: result.id });

  return { initPoint: result.init_point, preferenceId: result.id };
});

// ── 2. Webhook de MercadoPago ────────────────────────────────────────
exports.mpWebhook = onRequest(async (req, res) => {
  const { type, data } = req.body;
  if (type !== 'payment' || !data?.id) return res.sendStatus(200);

  try {
    const client = new MercadoPagoConfig({ accessToken: MP_ACCESS_TOKEN });
    const payment = new Payment(client);
    const paymentData = await payment.get({ id: data.id });

    const orderId = paymentData.external_reference;
    const status = paymentData.status; // approved, rejected, pending

    if (!orderId) return res.sendStatus(200);

    const update = { 'paymentStatus': status === 'approved' ? 'confirmed' : (status === 'rejected' ? 'failed' : 'pending') };
    if (status === 'approved') {
      update['status'] = 'accepted';
      update['statusHistory'] = require('firebase-admin/firestore').FieldValue.arrayUnion({
        status: 'accepted',
        timestamp: new Date(),
        note: 'Pago confirmado vía MercadoPago.',
      });
    }

    await db.collection('orders').doc(orderId).update(update);
    res.sendStatus(200);
  } catch (err) {
    console.error('MP Webhook error:', err);
    res.sendStatus(500);
  }
});

// ── 3. Notificar al cliente cuando cambia el estado del pedido ────────
exports.sendStatusNotification = onDocumentUpdated('orders/{orderId}', async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  if (before.status === after.status) return; // Sin cambio de estado

  const userId = after.userId;
  if (!userId) return; // Pedido de invitado, sin push

  const userDoc = await db.collection('users').doc(userId).get();
  if (!userDoc.exists || !userDoc.data().fcmToken) return;

  const fcmToken = userDoc.data().fcmToken;
  const statusLabels = {
    pending: 'Pendiente',
    received: 'Recibido',
    accepted: 'Aceptado',
    rejected: 'Rechazado',
    awaiting_payment: 'A la espera de pago',
    processing: 'Procesándose',
    paused: 'Pausado',
    ready: '¡Tu pedido está listo!',
    shipped: 'Enviado',
    completed: 'Completado',
    cancelled: 'Cancelado',
  };

  const statusLabel = statusLabels[after.status] || after.status;

  await getMessaging().send({
    token: fcmToken,
    notification: {
      title: `CraftBloom — Pedido ${after.orderCode}`,
      body: `Tu pedido está ahora: ${statusLabel}`,
    },
    data: {
      orderId: event.params.orderId,
      orderCode: after.orderCode,
      status: after.status,
    },
  });
});

// ── 4. Notificar a admins cuando llega un nuevo pedido ────────────────
exports.notifyAdminNewOrder = onDocumentUpdated('orders/{orderId}', async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  // Solo cuando se crea el pedido (pasa de null a pending — en realidad usamos onCreate)
  // Este trigger es para el primer cambio de estado
  if (before.status !== 'pending' || after.status !== 'received') return;

  const adminsSnap = await db.collection('users')
    .where('role', 'in', ['admin', 'worker'])
    .get();

  const tokens = adminsSnap.docs
    .map(d => d.data().fcmToken)
    .filter(Boolean);

  if (tokens.length === 0) return;

  await getMessaging().sendEachForMulticast({
    tokens,
    notification: {
      title: 'CraftBloom — Nuevo pedido',
      body: `Pedido ${after.orderCode} de ${after.customerName}`,
    },
    data: {
      orderId: event.params.orderId,
      orderCode: after.orderCode,
    },
  });
});

// ── 5. Agregar métricas diarias (se ejecuta manualmente o vía scheduler) ──
exports.aggregateDailyMetrics = onCall(async (request) => {
  const today = new Date().toISOString().split('T')[0];
  const startOfDay = new Date(today);
  const endOfDay = new Date(today);
  endOfDay.setDate(endOfDay.getDate() + 1);

  const ordersSnap = await db.collection('orders')
    .where('createdAt', '>=', startOfDay)
    .where('createdAt', '<', endOfDay)
    .get();

  let ordersCreated = 0, ordersCompleted = 0, ordersCancelled = 0, revenue = 0;

  for (const doc of ordersSnap.docs) {
    const order = doc.data();
    ordersCreated++;
    if (order.status === 'completed') { ordersCompleted++; revenue += order.totalPrice || 0; }
    if (order.status === 'cancelled') ordersCancelled++;
  }

  await db.collection('analytics_summary').doc(today).set({
    date: today,
    ordersCreated,
    ordersCompleted,
    ordersCancelled,
    revenue,
    updatedAt: new Date(),
  }, { merge: true });

  return { success: true, date: today };
});
