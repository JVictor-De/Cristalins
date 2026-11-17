package br.com.cristalins.assinatura

import android.app.Activity
import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.lang.ref.WeakReference

/**
 * Engine Flutter compartilhado + MethodChannel de Intents explícitas (AP2).
 * Cache id e channel alinhados a `artefatos/SPEC_ACTIVITIES.md`.
 *
 * O channel é registrado **uma vez** no engine; [anexarHost] atualiza a Activity
 * ativa (evita startActivity com host já destruído).
 */
object CristalinsEngine {
    const val ENGINE_ID = "cristalins_engine"
    const val CHANNEL = "br.com.cristalins.assinatura/navegacao"

    private val whitelist: Map<String, Class<out Activity>> = mapOf(
        "MainActivity" to MainActivity::class.java,
        "BoasVindasActivity" to BoasVindasActivity::class.java,
        "CadastroLoginActivity" to CadastroLoginActivity::class.java,
        "QuizActivity" to QuizActivity::class.java,
        "ResultadoActivity" to ResultadoActivity::class.java,
        "CatalogoActivity" to CatalogoActivity::class.java,
        "EnderecoActivity" to EnderecoActivity::class.java,
        "PlanoPagamentoActivity" to PlanoPagamentoActivity::class.java,
        "MinhaAssinaturaActivity" to MinhaAssinaturaActivity::class.java,
    )

    @Volatile
    private var hostRef: WeakReference<FlutterActivity>? = null

    @Volatile
    private var channelRegistrado = false

    fun obterOuCriar(context: Context, rotaInicial: String = "/"): FlutterEngine {
        val cache = FlutterEngineCache.getInstance()
        cache.get(ENGINE_ID)?.let { cached ->
            registrarChannelSePreciso(cached)
            return cached
        }

        val engine = FlutterEngine(context.applicationContext)
        GeneratedPluginRegistrant.registerWith(engine)
        engine.navigationChannel.setInitialRoute(rotaInicial)
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault(),
        )
        registrarChannelSePreciso(engine)
        cache.put(ENGINE_ID, engine)
        return engine
    }

    /** Mantém a Activity viva como host das Intents (chamar em onResume / configureFlutterEngine). */
    fun anexarHost(activity: FlutterActivity) {
        hostRef = WeakReference(activity)
    }

    fun limparHost(activity: FlutterActivity) {
        if (hostRef?.get() === activity) {
            hostRef = null
        }
    }

    /** Compat: anexa host e garante channel no [engine]. */
    fun registrarChannel(activity: FlutterActivity, engine: FlutterEngine) {
        anexarHost(activity)
        registrarChannelSePreciso(engine)
    }

    private fun registrarChannelSePreciso(engine: FlutterEngine) {
        if (channelRegistrado) return
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "abrirActivity" -> {
                    try {
                        val host = hostRef?.get()
                        if (host == null || host.isFinishing || host.isDestroyed) {
                            result.error(
                                "sem_host",
                                "Nenhuma Activity ativa para disparar a Intent",
                                null,
                            )
                            return@setMethodCallHandler
                        }
                        @Suppress("UNCHECKED_CAST")
                        val args = call.arguments as? Map<String, Any?>
                        val nome = args?.get("activity") as? String
                        val extras = args?.get("extras") as? Map<*, *>
                        val finish = args?.get("finish") as? Boolean ?: false
                        val clazz = whitelist[nome]
                        if (clazz == null) {
                            result.error(
                                "activity_desconhecida",
                                "Activity não permitida: $nome",
                                null,
                            )
                            return@setMethodCallHandler
                        }
                        val intent = Intent(host, clazz)
                        extras?.forEach { (chave, valor) ->
                            if (chave is String && valor is String) {
                                intent.putExtra(chave, valor)
                            }
                        }
                        host.startActivity(intent)
                        if (finish) {
                            host.finish()
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("falha_intent", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        channelRegistrado = true
    }
}
