import importlib.util
import json
from pathlib import Path
import tempfile

spec = importlib.util.spec_from_file_location("installer", "install.py")
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)
with tempfile.TemporaryDirectory() as temporary:
    config = Path(temporary)
    data = config / "share"
    (config / "hypr").mkdir()
    (config / "omarchy").mkdir()
    (config / "hypr/hyprland.lua").write_text("-- Keep my rules\n")
    (config / "hypr/hyprland.lua").chmod(0o644)
    shell = config / "omarchy/shell.json"
    original = {"version": 1, "bar": {"layout": {"right": [{"id": "existing.widget"}]}}, "plugins": [{"id": "existing.service"}]}
    shell.write_text(json.dumps(original))
    installer.configure(config, data)
    stale = config / "omarchy/plugins" / installer.PLUGIN / "Removed.qml"
    stale.symlink_to(installer.ROOT / "Removed.qml")
    settings = json.loads(shell.read_text())
    settings["plugins"][-1]["focusedTransparency"] = 35
    shell.write_text(json.dumps(settings))
    installer.configure(config, data)
    assert (config / "hypr/hyprland.lua").read_text().count(installer.REQUIRE) == 1
    assert json.loads(shell.read_text())["plugins"][-1]["focusedTransparency"] == 35
    assert (config / "hypr/omartube.lua").is_symlink()
    assert not stale.is_symlink()
    assert (data / "applications/omartube.desktop").is_symlink()
    assert (data / "applications/omartube-controls.desktop").is_symlink()
    installer.configure(config, data, remove=True)
    assert json.loads(shell.read_text()) == original
    assert (config / "hypr/hyprland.lua").read_text() == "-- Keep my rules\n"
    assert (config / "hypr/hyprland.lua").stat().st_mode & 0o777 == 0o644
    assert not (config / "omarchy/plugins" / installer.PLUGIN).exists()
    assert not (config / "hypr/omartube.lua").exists()
    assert not (data / "applications/omartube.desktop").exists()
    assert not (data / "applications/omartube-controls.desktop").exists()
print("Install, reinstall, retained settings and uninstall passed")
