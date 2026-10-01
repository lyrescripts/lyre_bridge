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

"""Server gang membership and neutral ESX behavior."""

from lua_test_support import LuaTestCase


class ServerGangTests(LuaTestCase):
    def test_qb_and_qbx_gang_and_grade_follow_live_player_data(self):
        for name in ("qbcore", "qbox"):
            with self.subTest(provider=name):
                provider = self.provider("server", "players", name)
                player = provider.getPlayerFromId(provider, 1)
                self.assertEqual((player.getGang().name, player.getGang().grade), ("ballas", 2))
                self.g.nativePlayers[1].PlayerData.gang.grade = 4
                self.assertEqual(player.getGang().grade, 4)
                self.g.nativePlayers[1].PlayerData.gang = None
                self.assertEqual((player.getGang().name, player.getGang().grade), ("none", 0))
                self.setUp()

    def test_gang_snapshot_preserves_the_native_grade(self):
        provider = self.provider("server", "players", "qbox")
        player = provider.getPlayerFromId(provider, 1)
        self.assertEqual(player.getGang().grade, 2)
        self.assertEqual(self.g.nativePlayers[1].PlayerData.gang.grade.level, 2)

    def test_esx_server_has_no_native_gang(self):
        provider = self.provider("server", "players", "esx")
        player = provider.getPlayerFromId(provider, 1)
        self.assertEqual((player.getGang().name, player.getGang().grade), ("none", 0))

    def test_missing_players_still_return_false(self):
        for name in ("esx", "qbcore", "qbox"):
            provider = self.provider("server", "players", name)
            self.assertFalse(provider.getPlayerFromId(provider, 99))
