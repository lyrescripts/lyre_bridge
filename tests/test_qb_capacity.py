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

"""QB capacity checks use the inventory's weight and slot authority."""

from lua_test_support import LuaTestCase


class QbCapacityTests(LuaTestCase):
    def setUp(self):
        super().setUp()
        self.run_lua("""
        activeResources['qb-inventory']=true
        exports['qb-inventory']={CanAddItem=function(_, source, item, count)
            capacityArgs={source,item,count}
            return inventoryHasSpace, inventoryHasSpace and nil or 'slots'
        end}
        """)
        self.p = self.provider("server", "inventory", "qb")

    def test_inventory_capacity_result_controls_permission(self):
        self.g.inventoryHasSpace = False
        self.assertFalse(self.p.canCarryItem(self.p, 1, "gasoline", 2))
        self.g.inventoryHasSpace = True
        self.assertTrue(self.p.canCarryItem(self.p, 1, "gasoline", 2))
        self.assertEqual([self.g.capacityArgs[i] for i in range(1, 4)], [1, "gasoline", 2])

    def test_default_quantity_is_one(self):
        self.g.inventoryHasSpace = True
        self.assertTrue(self.p.canCarryItem(self.p, 1, "water", None))
        self.assertEqual(self.g.capacityArgs[3], 1)

    def test_unloaded_player_or_missing_inventory_cannot_carry(self):
        self.g.inventoryHasSpace = True
        self.assertFalse(self.p.canCarryItem(self.p, 99, "water", 1))
        self.g.activeResources["qb-inventory"] = False
        self.assertFalse(self.p.canCarryItem(self.p, 1, "water", 1))

    def test_invalid_quantities_do_not_reach_the_inventory(self):
        for count in (0, -1, 1.5, float("inf"), float("nan"), "two"):
            self.assertFalse(self.p.canCarryItem(self.p, 1, "water", count))
        self.assertIsNone(self.g.capacityArgs)
