import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';

const rootDir = fileURLToPath(new URL('..', import.meta.url));
const actionsDir = join(rootDir, 'actions');

const actionFolders = readdirSync(actionsDir, { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .sort();

if (actionFolders.length === 0) {
  throw new Error('No actions were found in the actions directory.');
}

for (const folder of actionFolders) {
  const actionFile = join(actionsDir, folder, 'action.yml');
  const readmeFile = join(actionsDir, folder, 'README.md');

  if (!existsSync(actionFile)) {
    throw new Error(`Missing action.yml for action: ${folder}`);
  }

  if (!existsSync(readmeFile)) {
    throw new Error(`Missing README.md for action: ${folder}`);
  }

  const actionSource = readFileSync(actionFile, 'utf8');

  for (const requiredField of ['name:', 'description:', 'runs:']) {
    if (!actionSource.includes(requiredField)) {
      throw new Error(`Action ${folder} is missing required field ${requiredField}`);
    }
  }
}

console.log(`Validated ${actionFolders.length} action(s).`);