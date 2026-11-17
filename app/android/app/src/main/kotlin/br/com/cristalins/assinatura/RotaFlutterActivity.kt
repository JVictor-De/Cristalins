package br.com.cristalins.assinatura

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/** Casca AP2: FlutterActivity com rota inicial e engine compartilhado. */
abstract class RotaFlutterActivity : FlutterActivity() {
    abstract fun rotaInicial(): String

    override fun getInitialRoute(): String = rotaInicial()

    override fun provideFlutterEngine(context: Context): FlutterEngine =
        CristalinsEngine.obterOuCriar(context, rotaInicial())

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

class BoasVindasActivity : RotaFlutterActivity() {
    override fun rotaInicial() = "/boas-vindas"
}

class CadastroLoginActivity : RotaFlutterActivity() {
    override fun rotaInicial() = "/cadastro-login"
}

class QuizActivity : RotaFlutterActivity() {
    override fun rotaInicial() = "/quiz"
}

class ResultadoActivity : RotaFlutterActivity() {
    override fun rotaInicial() = "/resultado"
}

class CatalogoActivity : RotaFlutterActivity() {
    override fun rotaInicial() = "/catalogo"
}

class EnderecoActivity : RotaFlutterActivity() {
    override fun rotaInicial() = "/endereco"
}

class PlanoPagamentoActivity : RotaFlutterActivity() {
    override fun rotaInicial() = "/plano-pagamento"
}

class MinhaAssinaturaActivity : RotaFlutterActivity() {
    override fun rotaInicial() = "/minha-assinatura"
}
