package com.example.vaca_tec

import android.content.ActivityNotFoundException
import android.content.Intent
import androidx.core.content.FileProvider
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    // Abre los documentos de los animales (PDF, Word…) con la app que el usuario tenga instalada.
    // Los archivos viven en la carpeta "files/documentos" de la app y se comparten con un FileProvider.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
}
