'use strict';

const path = require('path');
const os = require('os');
const fs = require('fs');

const WEZTERM_CONFIG_DIR = path.join(os.homedir(), '.config', 'wezterm');
const PICOSH_FILES = ['picosh.lua', 'clipboard_image.ps1'];

for (const file of PICOSH_FILES) {
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
