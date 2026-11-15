/** Mock CJS de `@nestjs/schedule` — o pacote real é ESM e quebra o Jest 30. */
class ScheduleRootModule {}

module.exports = {
  ScheduleModule: {
    forRoot: () => ({
      module: ScheduleRootModule,
      global: true,
      providers: [],
      exports: [],
    }),
  },
  Cron: () => () => undefined,
  CronExpression: {
    EVERY_MINUTE: '* * * * *',
    EVERY_HOUR: '0 * * * *',
    EVERY_DAY_AT_MIDNIGHT: '0 0 * * *',
  },
};
