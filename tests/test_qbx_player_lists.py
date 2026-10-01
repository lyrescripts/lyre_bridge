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

"""QBX player maps, duty filtering and spatial player lookups."""

from lua_test_support import LuaTestCase


class QbxPlayerListTests(LuaTestCase):
    def setUp(self):
        super().setUp()
        self.run_lua("""
        nativePlayers[2]={PlayerData={source=2,citizenid='OWNER2',charinfo={},job={name='police',onduty=false}}}
        nativePlayers[3]={PlayerData={source=3,citizenid='OWNER3',charinfo={},job={name='ambulance',onduty=true}}}
        local vector={}; vector.__len=function(value) return math.abs(value.x) end
        vector.__sub=function(a,b) return setmetatable({x=a.x-b.x},vector) end
        function coords(x) return setmetatable({x=x},vector) end
        function GetPlayerPed(id) return id end
        function GetEntityCoords(id) return coords(id==3 and 100 or id) end
        function GetEntityHealth(id) return id==2 and 0 or 100 end
        """)
        self.p = self.provider("server", "players", "qbox")

    def test_online_players_use_the_logged_in_player_map(self):
        result = self.p.getOnlinePlayers(self.p)
        self.assertEqual(sorted(player.source for _, player in result.items()), [1, 2, 3])

    def test_job_and_duty_filtering(self):
        result = self.p.getOnlinePlayersByJob(self.p, "police", True)
        self.assertEqual([player.source for _, player in result.items()], [1])
        result = self.p.getOnlinePlayersByJob(self.p, self.lua.table_from(["police", "ambulance"]), False)
        self.assertEqual(len(result), 3)

    def test_nearby_players_honor_exclusions_and_health(self):
        result = self.p.getPlayersInZone(self.p, self.g.coords(0), 5)
        self.assertEqual([player.source for _, player in result.items()], [1])
        options = self.lua.table_from({"includeDead": True, "exceptions": self.lua.table_from({1: True})})
        result = self.p.getPlayersInZone(self.p, self.g.coords(0), 5, options)
        self.assertEqual([player.source for _, player in result.items()], [2])

    def test_empty_and_unloaded_players_are_skipped(self):
        self.run_lua("exports.qbx_core.GetPlayer=function() return nil end")
        self.assertEqual(len(self.p.getOnlinePlayers(self.p)), 0)
        self.run_lua("nativePlayers={}")
        self.assertEqual(len(self.p.getOnlinePlayersByJob(self.p, "police", True)), 0)
