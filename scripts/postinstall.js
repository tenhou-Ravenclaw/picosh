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

// Files managed by picosh (never touch wezterm.lua if it already exists)
const PICOSH_FILES = ['picosh.lua', 'clipboard_image.ps1'];

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

  for (const file of PICOSH_FILES) {
    const src = path.join(SRC_DIR, file);
    const dest = path.join(WEZTERM_CONFIG_DIR, file);
    if (fs.existsSync(dest)) {
      fs.copyFileSync(dest, dest + '.bak');
      console.error(`[picosh] Backed up existing ${file} → ${file}.bak`);
    }
    fs.copyFileSync(src, dest);
    console.error(`[picosh] Copied ${file} → ${dest}`);
  }

  const weztermLua = path.join(WEZTERM_CONFIG_DIR, 'wezterm.lua');
  if (!fs.existsSync(weztermLua)) {
    fs.copyFileSync(path.join(SRC_DIR, 'wezterm.lua'), weztermLua);
    console.error('[picosh] Created wezterm.lua (starter template)');
  } else {
    const content = fs.readFileSync(weztermLua, 'utf8');
    if (!content.includes("require('picosh')") && !content.includes('require("picosh")')) {
      console.error('[picosh] wezterm.lua already exists. Add the following line before "return config":');
      console.error('');
      console.error("  require('picosh').apply(config)");
      console.error('');
    }
  }
}

if (!weztermInstalled()) {
  const ok = installWezterm();
  if (!ok) process.exit(0);
}

copyConfigs();
console.error('[picosh] Done! Launch WezTerm to start using picosh.');
