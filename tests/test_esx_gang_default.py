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

"""ESX does not grant a native gang or gang duty by default."""

from lua_test_support import LuaTestCase


class EsxGangDefaultTests(LuaTestCase):
    def test_client_gang_default_is_neutral(self):
        self.load("bridges/client/players/esx.lua")
        provider = self.g.providers["client:players:esx"]
        self.assertEqual(provider.getGang(provider), "none")
        self.assertEqual(provider.getGangRank(provider), 0)
        self.assertFalse(provider.isOnGangDuty(provider))

    def test_server_and_client_defaults_agree(self):
        server = self.provider("server", "players", "esx")
        self.load("bridges/client/players/esx.lua")
        client = self.g.providers["client:players:esx"]
        self.assertEqual(server.getPlayerFromId(server, 1).getGang().name, client.getGang(client))
