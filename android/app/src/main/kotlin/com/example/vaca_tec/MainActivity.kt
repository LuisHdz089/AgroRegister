package com.example.vaca_tec

import android.Manifest
import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Abre los documentos de los animales (PDF, Word…) con la app que el usuario tenga instalada.
        // Los archivos viven en la carpeta "files/documentos" de la app y se comparten con un FileProvider.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vacatec/archivos").setMethodCallHandler { call, result ->
            if (call.method != "abrir") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            try {
                val archivo = File(call.argument<String>("ruta")!!)
                val uri = FileProvider.getUriForFile(this, "$packageName.archivos", archivo)
                val intent = Intent(Intent.ACTION_VIEW)
                    .setDataAndType(uri, contentResolver.getType(uri) ?: "*/*")
                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                startActivity(intent)
                result.success("ok")
            } catch (e: ActivityNotFoundException) {
                result.success("sinApp")
            } catch (e: Exception) {
                result.error("error", e.message, null)
            }
        }

        // Notificaciones de los avisos de campo (ver lib/notificaciones_sistema.dart).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "agroregister/notificaciones")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "permiso" -> {
                        pedirPermisoNotificaciones()
                        result.success(null)
                    }
                    "mostrar" -> {
                        mostrarNotificacion(
                            call.argument<Int>("id")!!,
                            call.argument<String>("titulo")!!,
                            call.argument<String>("texto")!!,
                        )
                        result.success(null)
                    }
                    "quitar" -> {
                        NotificationManagerCompat.from(this).cancelAll()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // Desde Android 13 hay que pedir permiso para mostrar notificaciones.
    private fun puedeNotificar() = Build.VERSION.SDK_INT < 33 ||
        ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) ==
        PackageManager.PERMISSION_GRANTED

    private fun pedirPermisoNotificaciones() {
        if (!puedeNotificar()) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 7)
        }
    }

    @SuppressLint("MissingPermission") // se revisa con puedeNotificar() antes de notificar
    private fun mostrarNotificacion(id: Int, titulo: String, texto: String) {
        if (!puedeNotificar()) return
        if (Build.VERSION.SDK_INT >= 26) {
            val canal = NotificationChannel(CANAL_AVISOS, "Avisos de campo", NotificationManager.IMPORTANCE_DEFAULT)
            canal.description = "Vacunas, aretado, tratamientos e incidencias pendientes"
            getSystemService(NotificationManager::class.java).createNotificationChannel(canal)
        }
        // Al tocar la notificación se abre (o vuelve al frente) la app.
        val abrir = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val notificacion = NotificationCompat.Builder(this, CANAL_AVISOS)
            .setSmallIcon(R.drawable.ic_notificacion)
            .setColor(0xFF1E5B3F.toInt())
            .setContentTitle(titulo)
            .setContentText(texto)
            .setStyle(NotificationCompat.BigTextStyle().bigText(texto))
            .setContentIntent(abrir)
            .setAutoCancel(true)
            .build()
        NotificationManagerCompat.from(this).notify(id, notificacion)
    }

    // Oculta la barra de navegación del sistema (se conserva la de estado). Deslizando desde abajo
    // aparece un momento y se vuelve a ocultar. Se aplica cada vez que la app recupera el foco
    // (al abrirla, al volver de otra app o al cerrar un diálogo del sistema).
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (!hasFocus) return
        WindowCompat.getInsetsController(window, window.decorView).apply {
            hide(WindowInsetsCompat.Type.navigationBars())
            systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        }
    }

    companion object {
        private const val CANAL_AVISOS = "avisos_campo"
    }
}
