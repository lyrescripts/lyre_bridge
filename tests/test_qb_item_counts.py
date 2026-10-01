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

"""All matching QB slots contribute to quantity and ownership checks."""

from lua_test_support import LuaTestCase


class QbItemCountTests(LuaTestCase):
    def setUp(self):
        super().setUp()
        self.run_lua("nativePlayers[1].PlayerData.items={[1]={name='gasoline',amount=1},[7]={name='gasoline',amount=5},[8]={name='water',amount=20}}")
        self.p = self.provider("server", "inventory", "qb")

    def test_sparse_slots_are_summed_and_other_items_are_excluded(self):
        self.assertEqual(self.p.getItemCount(self.p, 1, "gasoline"), 6)
        self.assertEqual(self.p.getItemCount(self.p, 1, "GASOLINE"), 6)
        self.assertTrue(self.p.hasItem(self.p, 1, "gasoline", 6))
        self.assertFalse(self.p.hasItem(self.p, 1, "gasoline", 7))

    def test_player_wrapper_uses_the_same_total(self):
        provider = self.provider("server", "players", "qbcore")
        player = provider.getPlayerFromId(provider, 1)
        self.assertEqual(player.getItemCount("gasoline"), 6)
        self.g.nativePlayers[1].PlayerData["items"] = self.lua.table()
        self.assertEqual(player.getItemCount("gasoline"), 0)

    def test_unknown_item_invalid_name_and_unloaded_player_have_zero_count(self):
        self.assertEqual(self.p.getItemCount(self.p, 1, "missing"), 0)
        self.assertEqual(self.p.getItemCount(self.p, 1, None), 0)
        self.assertEqual(self.p.getItemCount(self.p, 99, "gasoline"), 0)
