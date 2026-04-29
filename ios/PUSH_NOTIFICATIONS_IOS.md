# Push Notifications en iOS – Configuración

La app ya tiene el código listo para recibir notificaciones push en iOS (mismo flujo que en Android). Para que funcionen en un dispositivo o simulador real necesitas completar estos pasos **una sola vez**.

## 1. Añadir la app iOS al proyecto Firebase

1. Entra en [Firebase Console](https://console.firebase.google.com/) y abre el proyecto (el mismo que usa Android).
2. En la configuración del proyecto, **Añadir app** → elige **iOS**.
3. **Bundle ID**: debe coincidir con el de Xcode. En este proyecto es **`com.fidesoft.raintex.app`**. Usa exactamente este en Firebase al dar de alta la app iOS.
4. Descarga el archivo **GoogleService-Info.plist** que te ofrece Firebase.
5. **Añade el archivo al proyecto:**
   - Arrastra `GoogleService-Info.plist` a la carpeta **Runner** dentro de Xcode (en el grupo Runner, al mismo nivel que Info.plist).
   - Marca **Copy items if needed** y que el target **Runner** esté seleccionado.

Sin este archivo, Firebase no se inicializa en iOS y no obtendrás token FCM.

## 2. Habilitar Push Notifications en Xcode

1. Abre `ios/Runner.xcworkspace` en Xcode (no el `.xcodeproj`).
2. Selecciona el target **Runner** → pestaña **Signing & Capabilities**.
3. Pulsa **+ Capability** y añade **Push Notifications**.
4. (Opcional) Añade **Background Modes** y marca **Remote notifications** si no lo tienes ya (el proyecto ya incluye `remote-notification` en Info.plist).

El archivo `Runner.entitlements` ya incluye `aps-environment`. Si Xcode añade o modifica algo al agregar la capacidad, déjalo como esté.

## 3. Entitlements para desarrollo y producción

- En `Runner.entitlements` está `aps-environment` = **development** (para desarrollo y debug).
- Para **publicar en App Store o TestFlight**, en Xcode cambia a **Release** y asegúrate de que la capacidad Push Notifications use el perfil de distribución; Xcode puede poner `aps-environment` = **production** automáticamente según el perfil. Si lo editas a mano, en release usa `production`.

## 4. Resumen de lo que hace la app en iOS

- **Permisos**: Se piden al iniciar (alertas, badge, sonido) vía Firebase, igual que en Android.
- **Token FCM**: Se obtiene y se envía al backend con plataforma `I` (iOS) al hacer login.
- **Notificaciones en primer plano**: Se muestran como notificación local (título, cuerpo y tap → pendientes de aprobar).
- **Notificaciones en segundo plano o app cerrada**: Las maneja Firebase; al tocar se abre la app y se navega a vacaciones o permisos pendientes según el payload.

No hace falta cambiar nada más en el código Dart para que el comportamiento sea el mismo que en Android.
