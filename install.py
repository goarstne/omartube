#!/usr/bin/python3
"""Install or remove OmarTube's user-owned rules and shell plugin."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
from datetime import datetime

ROOT = Path(__file__).resolve().parent
PLUGIN = "goarstne.omartube"
FILES = ("manifest.json", "BarWidget.qml", "Panel.qml", "Service.qml")
REQUIRE = 'require("hypr.omartube")'


def backup(path):
    return path.with_name(path.name + ".bak." + datetime.now().strftime("%Y%m%d-%H%M%S-%f"))


def write(path, text):
    if path.read_text() == text:
        return
    path = path.resolve()  # keep a symlinked (dotfiles-managed) config a symlink
    shutil.copy2(path, backup(path))
    fd, temporary = tempfile.mkstemp(dir=path.parent)
    try:
        os.fchmod(fd, path.stat().st_mode & 0o777)
        with os.fdopen(fd, "w") as stream:
            stream.write(text)
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


def configure(config, data, remove=False):
    hypr = config / "hypr/hyprland.lua"
    shell = config / "omarchy/shell.json"
    content = hypr.read_text()
    settings = json.loads(shell.read_text())
    layout = settings.setdefault("bar", {}).setdefault("layout", {})
    entries = settings.setdefault("plugins", [])
    plugin_dir = config / "omarchy/plugins" / PLUGIN
    links = [(config / "hypr/omartube.lua", ROOT / "omartube.lua")]
    links += [(plugin_dir / name, ROOT / name) for name in FILES]
    applications = data / "applications"
    links += [(applications / name, ROOT / name) for name in ("omartube.desktop", "omartube-controls.desktop")]
    if plugin_dir.is_symlink():
        raise RuntimeError("Plugin directory is already a symlink; inspect it before installing.")
    if plugin_dir.is_dir():
        for stale in plugin_dir.iterdir():  # links to source files that no longer exist
            if stale.is_symlink() and stale.name not in FILES and ROOT in stale.resolve().parents:
                stale.unlink()
    if remove:
        content = "\n".join(line for line in content.split("\n") if line.strip() != REQUIRE)
        settings["plugins"] = [entry for entry in entries if entry.get("id") != PLUGIN]
        for section, items in layout.items():
            layout[section] = [entry for entry in items if entry.get("id") != PLUGIN]
        for target, source in links:
            if target.is_symlink() and target.resolve() == source:
                target.unlink()
        if plugin_dir.is_dir() and not any(plugin_dir.iterdir()):
            plugin_dir.rmdir()
    else:
        plugin_dir.mkdir(parents=True, exist_ok=True)
        applications.mkdir(parents=True, exist_ok=True)
        for target, source in links:
            if target.is_symlink() and target.resolve() == source:
                continue
            if target.exists() or target.is_symlink():
                target.rename(backup(target))
            target.symlink_to(source)
        if REQUIRE not in [line.strip() for line in content.splitlines()]:
            content += ("" if content.endswith("\n") else "\n") + REQUIRE + "\n"
        if not any(entry.get("id") == PLUGIN for entry in entries):
            entries.append({"id": PLUGIN, "focusedTransparency": 10, "unfocusedTransparency": 15})
        if not any(entry.get("id") == PLUGIN for items in layout.values() for entry in items):
            layout.setdefault("right", []).insert(0, {"id": PLUGIN})
    write(hypr, content)
    write(shell, json.dumps(settings, indent=2) + "\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--uninstall", action="store_true")
    args = parser.parse_args()
    config = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    data = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
    configure(config, data, args.uninstall)
    env = {**os.environ, "PATH": "/usr/bin:/bin"}  # omarchy-shell resolves qs through PATH
    subprocess.run(["/usr/bin/hyprctl", "reload"], check=True, env=env)
    subprocess.run(["/usr/bin/hyprctl", "configerrors"], check=True, env=env)
    subprocess.run(["/usr/share/omarchy/bin/omarchy-shell", "shell", "rescanPlugins"], check=True, env=env)
