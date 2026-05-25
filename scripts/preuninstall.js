'use strict';

const path = require('path');
const os = require('os');
const fs = require('fs');

const WEZTERM_CONFIG_DIR = path.join(os.homedir(), '.config', 'wezterm');
const PICOSH_FILES = ['picosh.lua', 'picosh-notify.ps1', 'clipboard_image.ps1'];

function removeConfigs() {
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
}

function unregisterClaudeHook() {
  const settingsPath = path.join(os.homedir(), '.claude', 'settings.json');
  if (!fs.existsSync(settingsPath)) return;

  let settings;
  try {
    settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
  } catch (e) { return; }

  if (!settings.hooks || !settings.hooks.Stop) return;

  settings.hooks.Stop = settings.hooks.Stop.filter(
    (entry) => !(entry.hooks && entry.hooks.some((h) => h.command && h.command.includes('picosh-notify')))
  );

  if (settings.hooks.Stop.length === 0) delete settings.hooks.Stop;
  if (Object.keys(settings.hooks).length === 0) delete settings.hooks;

  fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2));
  console.error('[picosh] Unregistered Stop hook from ~/.claude/settings.json');
}

removeConfigs();
unregisterClaudeHook();
