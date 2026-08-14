import { readdirSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';

const actionsDir = fileURLToPath(new URL('../actions/', import.meta.url));
const entries = readdirSync(actionsDir, { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .filter((name) => existsSync(join(actionsDir, name, 'action.yml')))
  .sort();

for (const name of entries) {
  console.log(name);
}