package br.com.cristalins.assinatura

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Launcher (único `exported` + MAIN/LAUNCHER).
 * Rota `/` = splash; engine cache compartilhado com as cascas AP2.
 */
class MainActivity : FlutterActivity() {
    override fun getInitialRoute(): String = "/"

    override fun provideFlutterEngine(context: Context): FlutterEngine =
        CristalinsEngine.obterOuCriar(context, "/")

    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        CristalinsEngine.registrarChannel(this, flutterEngine)
    }

    override fun onResume() {
        super.onResume()
        CristalinsEngine.anexarHost(this)
    }

    override fun onDestroy() {
        CristalinsEngine.limparHost(this)
        super.onDestroy()
    }
}
