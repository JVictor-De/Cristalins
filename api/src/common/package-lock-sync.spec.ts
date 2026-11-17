import { readFileSync } from 'fs';
import { join } from 'path';

/**
 * Coolify (Node 22 / npm 10) falha no `npm ci` se peers opcionais sumirem do lock
 * ao regenerar com npm mais novo. Mantém chokidar/readdirp explícitos.
 */
describe('package-lock sync (Coolify npm ci)', () => {
  const root = join(__dirname, '../..');
  const pkg = JSON.parse(readFileSync(join(root, 'package.json'), 'utf8')) as {
    optionalDependencies?: Record<string, string>;
  };
  const lock = JSON.parse(readFileSync(join(root, 'package-lock.json'), 'utf8')) as {
    packages: Record<string, { version?: string; optionalDependencies?: Record<string, string> }>;
  };

  it('declara chokidar@4.0.3 e readdirp@4.1.2 em optionalDependencies', () => {
    expect(pkg.optionalDependencies).toEqual({
      chokidar: '4.0.3',
      readdirp: '4.1.2',
    });
  });

  it('lock espelha optionalDependencies e contém os pacotes', () => {
    expect(lock.packages['']?.optionalDependencies).toEqual(pkg.optionalDependencies);
    expect(lock.packages['node_modules/chokidar']?.version).toBe('4.0.3');
    expect(lock.packages['node_modules/readdirp']?.version).toBe('4.1.2');
  });
});
