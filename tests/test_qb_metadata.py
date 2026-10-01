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

"""QB slot metadata is persisted and failed writes leave native data intact."""

from lua_test_support import LuaTestCase


class QbMetadataTests(LuaTestCase):
    def setUp(self):
        super().setUp()
        self.run_lua("""
        nativePlayers[1].PlayerData.items = {
            [1]={name='gasoline',amount=1,slot=1,info={fuelAmount=100}},
            [2]={name='water',amount=2,slot=2,info={label='Water'}},
        }
        writes=0
        nativePlayers[1].Functions.SetInventory=function(items)
            writes=writes+1
            if failWrite then return false end
            nativePlayers[1].PlayerData.items=items
        end
        """)
        self.p = self.provider("server", "inventory", "qb")

    def test_fuel_remaining_is_saved_on_the_matching_slot(self):
        metadata = self.lua.table_from({"fuelAmount": 25})
        self.assertTrue(self.p.setItemMetadata(self.p, 1, "gasoline", 1, metadata))
        item = self.g.nativePlayers[1].PlayerData["items"][1]
        self.assertEqual((item.info.fuelAmount, item.amount, item.slot), (25, 1, 1))
        self.assertEqual(self.g.nativePlayers[1].PlayerData["items"][2].info.label, "Water")
        self.assertEqual(self.g.writes, 1)

    def test_invalid_slot_item_or_metadata_never_writes(self):
        for slot, item, metadata in ((0, "gasoline", {}), (1.5, "gasoline", {}),
                                     (9, "gasoline", {}), (1, "water", {}), (1, "gasoline", None)):
            with self.subTest(slot=slot, item=item):
                value = self.lua.table_from(metadata) if metadata is not None else None
                self.assertFalse(self.p.setItemMetadata(self.p, 1, item, slot, value))
        self.assertEqual(self.g.writes, 0)

    def test_failed_save_does_not_mutate_original_items(self):
        self.g.failWrite = True
        self.assertFalse(self.p.setItemMetadata(self.p, 1, "gasoline", 1, self.lua.table_from({"fuelAmount": 10})))
        self.assertEqual(self.g.nativePlayers[1].PlayerData["items"][1].info.fuelAmount, 100)

    def test_missing_player_or_inventory_setter_fails(self):
        self.assertFalse(self.p.setItemMetadata(self.p, 99, "gasoline", 1, self.lua.table()))
        self.g.nativePlayers[1].Functions.SetInventory = None
        self.assertFalse(self.p.setItemMetadata(self.p, 1, "gasoline", 1, self.lua.table()))
