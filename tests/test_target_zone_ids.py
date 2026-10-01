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

"""Bridge zone identifiers survive native creation and cleanup."""

from lua_test_support import LuaTestCase


class TargetZoneIdTests(LuaTestCase):
    def setUp(self):
        super().setUp()
        self.run_lua("""
        zones, removed={},{}
        exports.ox_target={
            addSphereZone=function(_,parameters)
                if failZone then return nil end
                capturedZone=parameters
                zones[parameters.name or 42]=parameters
                return 42
            end,
            removeZone=function(_,id) removed[#removed+1]=id; zones[id]=nil end,
        }
        """)
        self.p = self.provider("client", "target", "ox_target")

    def test_bridge_id_is_used_as_the_native_name_and_can_be_removed(self):
        zone = self.lua.table_from({"id": "garage_park", "radius": 3, "options": self.lua.table()})
        result = self.p.addSphereZone(self.p, zone)
        self.assertEqual(result, "garage_park")
        self.assertEqual(self.g.capturedZone.name, "garage_park")
        self.assertIsNone(zone.name)
        self.p.removeZone(self.p, result)
        self.assertIsNone(self.g.zones["garage_park"])

    def test_existing_native_name_and_anonymous_ids_still_work(self):
        result = self.p.addSphereZone(self.p, self.lua.table_from({"name": "named_zone"}))
        self.assertEqual(result, "named_zone")
        result = self.p.addSphereZone(self.p, self.lua.table())
        self.assertEqual(result, 42)
        self.p.removeZone(self.p, result)
        self.assertIsNone(self.g.zones[42])

    def test_failed_creation_does_not_return_a_successful_name(self):
        self.g.failZone = True
        self.assertIsNone(self.p.addSphereZone(self.p, self.lua.table_from({"id": "failed"})))

    def test_options_and_custom_fields_reach_the_native_unchanged(self):
        self.run_lua("zoneInput={id='park',options={{label='Park',onSelect=function() selectionMade=true end}},distance=4,debug=true}")
        self.p.addSphereZone(self.p, self.g.zoneInput)
        self.assertEqual(self.g.capturedZone.distance, 4)
        self.assertTrue(self.g.capturedZone.debug)
        self.g.capturedZone.options[1].onSelect()
        self.assertTrue(self.g.selectionMade)
