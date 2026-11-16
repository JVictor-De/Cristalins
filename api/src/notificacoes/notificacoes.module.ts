import { Module } from '@nestjs/common';
import { criarCanalEmail, criarCanalPush } from './canais';
import { NotificacoesController, RecuperacaoSenhaController } from './notificacoes.controller';
import { NotificacoesService } from './notificacoes.service';
import { CANAL_EMAIL, CANAL_PUSH } from './notificacoes.tipos';
import { RecuperacaoSenhaService } from './recuperacao-senha.service';

/** Push (FCM), e-mail (SMTP) e recuperação de senha (RF51, RF52). */
@Module({
  controllers: [NotificacoesController, RecuperacaoSenhaController],
  providers: [
    { provide: CANAL_PUSH, useFactory: criarCanalPush },
    { provide: CANAL_EMAIL, useFactory: criarCanalEmail },
    NotificacoesService,
    RecuperacaoSenhaService,
  ],
  exports: [NotificacoesService],
})
export class NotificacoesModule {}
