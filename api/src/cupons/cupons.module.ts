import { Module } from '@nestjs/common';
import { CuponsController } from './cupons.controller';
import { CuponsService } from './cupons.service';

/** RN21: `POST /admin/cupons`. */
@Module({
  controllers: [CuponsController],
  providers: [CuponsService],
})
export class CuponsModule {}
