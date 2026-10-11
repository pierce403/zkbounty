import { cpSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';

const root = fileURLToPath(new URL('../', import.meta.url));
const output = resolve(root, 'dist');
const revision = process.env.CF_COMMIT_SHA || execFileSync('git', ['rev-parse', 'HEAD'], {
  cwd: root,
  encoding: 'utf8',
}).trim();
if (!/^[a-f0-9]{40}$/.test(revision)) throw new Error('Invalid source revision');

rmSync(output, { recursive: true, force: true });
mkdirSync(output, { recursive: true });
cpSync(resolve(root, 'site'), output, { recursive: true });
writeFileSync(resolve(output, 'deployment.json'), `${JSON.stringify({
  project: 'zkbounty',
  revision,
  kind: 'static-project-site',
}, null, 2)}\n`);
console.log(`Built static project site at ${revision}`);
