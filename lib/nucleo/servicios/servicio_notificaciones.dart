import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('Notificación en segundo plano recibida: ${message.messageId}');
  }
}

class ServicioNotificaciones {
  static final ServicioNotificaciones _instancia =
      ServicioNotificaciones._internas();
  factory ServicioNotificaciones() => _instancia;
  ServicioNotificaciones._internas();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _inicializado = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Inicializa Firebase Messaging, permisos y notificaciones locales.
  Future<void> inicializar() async {
    if (_inicializado) return;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Solicitar permisos de notificación (especial para iOS / Android 13+)
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        print('Permiso de notificaciones: ${settings.authorizationStatus}');
      }

      // Configurar canal de notificación local para Android
      const androidChannel = AndroidNotificationChannel(
        'barber_app_notifications',
        'Notificaciones de Barbería',
        description: 'Canal de notificaciones para citas, pagos y turnos',
        importance: Importance.high,
      );

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();

      await _localNotifications.initialize(
        settings: const InitializationSettings(
          android: androidInit,
          iOS: iosInit,
        ),
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // Escuchar notificaciones mientras la app está en primer plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final android = message.notification?.android;

        if (notification != null && !kIsWeb) {
          _localNotifications.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                androidChannel.id,
                androidChannel.name,
                channelDescription: androidChannel.description,
                icon: android?.smallIcon ?? '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
          );
        }
      });

      // Obtener el Token FCM del dispositivo
      _fcmToken = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        print('Token FCM generado: $_fcmToken');
      }

      // Escuchar renovación del token
      _firebaseMessaging.onTokenRefresh.listen((nuevoToken) {
        _fcmToken = nuevoToken;
        guardarTokenEnBackend(nuevoToken);
      });

      // Intentar guardar el token si el usuario ya inició sesión
      if (_fcmToken != null) {
        await guardarTokenEnBackend(_fcmToken!);
      }

      _inicializado = true;
    } catch (e) {
      if (kDebugMode) {
        print('Error al inicializar ServicioNotificaciones: $e');
      }
    }
  }

  /// Registra el token FCM del usuario en la tabla perfiles de Supabase.
  Future<void> guardarTokenEnBackend(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client
          .from('perfiles')
          .update({'fcm_token': token}).eq('id', user.id);
    } catch (e) {
      // Ignorar de forma segura si la columna fcm_token aún no fue agregada en remoto
      if (kDebugMode) {
        print('Nota sobre guardar fcm_token: $e');
      }
    }
  }
}
