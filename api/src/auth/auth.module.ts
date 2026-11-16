import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';
import { ThrottlerModule } from '@nestjs/throttler';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtAuthGuard, PapeisGuard } from './guards';
import { TokenService } from './token.service';

export const LIMITE_LOGIN_POR_MINUTO = 5;
/** Throttle de POST /precos/simular (público): por IP, janela de 1 minuto. */
export const LIMITE_SIMULAR_POR_MINUTO = 60;

@Module({
  imports: [
    // Segredo e validade vão em cada chamada (TokenService), lidos do ambiente.
    JwtModule.register({}),
    // Só aplicado onde houver @UseGuards(ThrottlerGuard): login e simular.
    ThrottlerModule.forRoot({
      throttlers: [
        { name: 'login', ttl: 60_000, limit: LIMITE_LOGIN_POR_MINUTO },
        { name: 'simular', ttl: 60_000, limit: LIMITE_SIMULAR_POR_MINUTO },
      ],
      errorMessage: 'Muitas tentativas de login. Aguarde um minuto e tente de novo.',
    }),
  ],
  controllers: [AuthController],
  providers: [
    TokenService,
    AuthService,
    // Ordem importa: autentica (JWT) e depois confere o papel.
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: PapeisGuard },
  ],
  exports: [TokenService],
})
export class AuthModule {}
