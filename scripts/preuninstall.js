'use strict';

const path = require('path');
const os = require('os');
const fs = require('fs');

const WEZTERM_CONFIG_DIR = path.join(os.homedir(), '.config', 'wezterm');
const SRC_DIR = path.join(__dirname, '..', 'wezterm');

const files = fs.readdirSync(SRC_DIR);
for (const file of files) {
  const dest = path.join(WEZTERM_CONFIG_DIR, file);
  const bak = dest + '.bak';
  try {
    fs.unlinkSync(dest);
    console.error(`[picosh] Removed ${dest}`);
    if (fs.existsSync(bak)) {
      fs.renameSync(bak, dest);
      console.error(`[picosh] Restored ${file}.bak → ${file}`);
    }
  } catch (_) {}
}
