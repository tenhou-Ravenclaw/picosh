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
const PICOSH_FILES = ['picosh.lua', 'picosh-notify.ps1', 'clipboard_image.ps1'];

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

function registerClaudeHook() {
  const settingsPath = path.join(os.homedir(), '.claude', 'settings.json');
  const notifyScript = path.join(WEZTERM_CONFIG_DIR, 'picosh-notify.ps1');
  const hookCommand = `powershell.exe -NoProfile -NonInteractive -File "${notifyScript}"`;

  let settings = {};
  if (fs.existsSync(settingsPath)) {
    try {
      settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
    } catch (e) {
      console.error('[picosh] Could not parse ~/.claude/settings.json, skipping hook registration');
      return;
    }
  }

  if (!settings.hooks) settings.hooks = {};
  if (!settings.hooks.Stop) settings.hooks.Stop = [];

  const alreadyRegistered = settings.hooks.Stop.some((entry) =>
    entry.hooks && entry.hooks.some((h) => h.command && h.command.includes('picosh-notify'))
  );

  if (!alreadyRegistered) {
    settings.hooks.Stop.push({
      matcher: '',
      hooks: [{type: 'command', command: hookCommand}],
    });
    fs.mkdirSync(path.dirname(settingsPath), {recursive: true});
    fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2));
    console.error('[picosh] Registered Stop hook in ~/.claude/settings.json');
  }
}

if (!weztermInstalled()) {
  const ok = installWezterm();
  if (!ok) process.exit(0);
}

copyConfigs();
registerClaudeHook();
console.error('[picosh] Done! Launch WezTerm to start using picosh.');
