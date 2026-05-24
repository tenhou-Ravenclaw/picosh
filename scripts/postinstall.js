'use strict';

const {execSync} = require('child_process');
const path = require('path');
const os = require('os');
const fs = require('fs');

if (os.platform() !== 'win32') {
  console.error('[picosh] Only Windows is supported.');
  process.exit(0);
}

const WEZTERM_EXE_PATHS = [
  path.join(os.homedir(), 'AppData', 'Local', 'Programs', 'WezTerm', 'wezterm.exe'),
  'C:\\Program Files\\WezTerm\\wezterm.exe',
];

const WEZTERM_CONFIG_DIR = path.join(os.homedir(), '.config', 'wezterm');

const SRC_DIR = path.join(__dirname, '..', 'wezterm');

function weztermInstalled() {
  return WEZTERM_EXE_PATHS.some((p) => fs.existsSync(p));
}

function installWezterm() {
  console.error('[picosh] Installing WezTerm via winget...');
  try {
    execSync('winget install wez.wezterm --silent', {stdio: 'inherit'});
    return true;
  } catch (e) {
    console.error('[picosh] Auto-install failed. Please install WezTerm manually: https://wezfurlong.org/wezterm/');
    return false;
  }
}

function copyConfigs() {
  fs.mkdirSync(WEZTERM_CONFIG_DIR, {recursive: true});

  const files = fs.readdirSync(SRC_DIR);
  for (const file of files) {
    const src = path.join(SRC_DIR, file);
    const dest = path.join(WEZTERM_CONFIG_DIR, file);
    if (fs.existsSync(dest)) {
      fs.copyFileSync(dest, dest + '.bak');
      console.error(`[picosh] Backed up existing ${file} → ${file}.bak`);
    }
    fs.copyFileSync(src, dest);
    console.error(`[picosh] Copied ${file} → ${dest}`);
  }
}

if (!weztermInstalled()) {
  const ok = installWezterm();
  if (!ok) process.exit(0);
}

copyConfigs();
console.error('[picosh] Done! Launch WezTerm to start using picosh.');
