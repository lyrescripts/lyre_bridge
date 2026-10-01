r"""
     _                       _____           _       _
    | |                     / ____|         (_)     | |      
    | |    _   _ _ __ ___  | (___   ___ _ __ _ _ __ | |_ ___ 
    | |   | | | | '__/ _ \  \___ \ / __| '__| | '_ \| __/ __|
    | |___| |_| | | |  __/  ____) | (__| |  | | |_) | |_\__ \
    |______\__, |_|  \___| |_____/ \___|_|  |_| .__/ \__|___/
            __/ |                             | |            
           |___/                              |_|

"""

"""Check the documented module surface and bootstrap of every provider."""

import re

from lua_test_support import LuaTestCase, ROOT


class ProviderSurfaceTests(LuaTestCase):
    def test_all_providers_parse_and_register(self):
        files = list((ROOT / "bridges").rglob("*.lua"))
        for path in files:
            with self.subTest(provider=path.relative_to(ROOT).as_posix()):
                self.load(path.relative_to(ROOT).as_posix())
        self.assertEqual(len(list(self.g.providers.items())), len(files))

    def test_all_providers_implement_their_documented_surface(self):
        contracts = {
            ("server", "players"): "BridgePlayers", ("client", "players"): "BridgeClientPlayer",
            ("server", "inventory"): "BridgeInventory", ("client", "inventory"): "BridgeClientInventory",
            ("server", "vehicle_storage"): "BridgeVehicleStorage", ("server", "vehicles"): "BridgeVehiclesServer",
            ("client", "vehicles"): "BridgeVehiclesClient", ("client", "target"): "BridgeTarget",
            ("client", "notifications"): "BridgeNotifications", ("server", "status"): "BridgeStatus",
            ("server", "society"): "BridgeSociety", ("client", "fuel"): "BridgeFuel",
            ("client", "progress"): "BridgeProgress", ("client", "skillcheck"): "BridgeSkillCheck",
            ("client", "vehicle_keys"): "BridgeVehicleKeys", ("server", "mysql"): "BridgeMysql",
            ("server", "usable_items"): "BridgeUsableItems", ("server", "dispatch"): "BridgeDispatch",
            ("client", "dispatch"): "BridgeDispatch",
        }
        fields, current = {}, None
        for line in (ROOT / "types.lua").read_text(encoding="utf-8-sig").splitlines():
            match = re.match(r"---@class (\w+)", line)
            if match:
                current = match[1]
                fields[current] = []
            match = re.match(r"---@field (\w+) fun\(", line)
            if match and current:
                fields[current].append(match[1])
        for path in (ROOT / "bridges").rglob("*.lua"):
            _, side, module, filename = path.relative_to(ROOT).parts
            self.load(path.relative_to(ROOT).as_posix())
            provider = self.g.providers[f"{side}:{module}:{path.stem}"]
            for method in fields[contracts[side, module]]:
                with self.subTest(provider=filename, method=method):
                    self.assertIsNotNone(provider[method])
