import { Body, Controller, HttpCode, HttpStatus, Post, UseGuards } from '@nestjs/common';
import {
  ApiOkResponse,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { ThrottlerGuard } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { Publico } from './decorators';
import { LoginDto, RefreshDto } from './dto/login.dto';
import { TokensResponse } from './dto/tokens.response';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('login')
  @Publico()
  @UseGuards(ThrottlerGuard) // SEG06: 5 tentativas por minuto por IP (CT19)
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ type: TokensResponse })
  @ApiUnauthorizedResponse({
    schema: { example: { codigo: 'CREDENCIAIS_INVALIDAS', mensagem: 'E-mail ou senha incorretos.' } },
  })
  @ApiTooManyRequestsResponse({
    description: 'CT19: 6ª tentativa no mesmo minuto',
    schema: { example: { codigo: 'MUITAS_TENTATIVAS', mensagem: 'Muitas tentativas de login. Aguarde um minuto e tente de novo.' } },
  })
  login(@Body() dto: LoginDto): Promise<TokensResponse> {
    return this.auth.login(dto.email, dto.senha);
  }

  @Post('refresh')
  @Publico()
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ type: TokensResponse })
  @ApiUnauthorizedResponse({ description: 'NAO_AUTENTICADO' })
  refresh(@Body() dto: RefreshDto): Promise<TokensResponse> {
    return this.auth.renovar(dto.refreshToken);
  }
}
