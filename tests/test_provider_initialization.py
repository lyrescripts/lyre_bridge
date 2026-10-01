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

"""Failed providers stay inactive, retry with a cooldown and allow fallback."""

from lua_test_support import LuaTestCase


class ProviderInitializationTests(LuaTestCase):
    def setUp(self):
        super().setUp()
        self.load("engine/registry.lua")
        self.load("engine/resolver.lua")
        self.run_lua("""
        attempts=0
        primary=LyreBridge.registerProvider('server','sample','primary',1)
        function primary:detect() return true end
        function primary:init()
            attempts=attempts+1
            if not initializationWorks then error('unavailable export') end
        end
        fallback=LyreBridge.registerProvider('server','sample','fallback',2)
        function fallback:detect() return true end
        """)

    def resolve(self):
        return self.g.LyreBridge.resolveProvider("server", "sample")

    def test_initialization_failure_uses_fallback_without_marking_primary_active(self):
        result = self.resolve()
        self.assertEqual(result["__name"], "fallback")
        self.assertIsNone(self.g.primary["__active"])
        self.assertEqual(self.g.attempts, 1)

    def test_failed_initialization_is_throttled_then_retried(self):
        self.resolve()
        self.g.initializationWorks = True
        self.g.clockTime = 999
        self.assertEqual(self.resolve()["__name"], "fallback")
        self.assertEqual(self.g.attempts, 1)
        self.g.clockTime = 1000
        self.assertEqual(self.resolve()["__name"], "primary")
        self.assertEqual(self.g.attempts, 2)
        self.assertTrue(self.g.primary["__active"])
        self.assertIsNone(self.g.primary["__initRetryAt"])
        self.resolve()
        self.assertEqual(self.g.attempts, 2)

    def test_forced_provider_does_not_dispatch_a_failed_initialization(self):
        self.g.convars["lyre_bridge:provider:server:sample:force"] = "primary"
        self.assertIsNone(self.resolve())
        self.assertIsNone(self.g.primary["__active"])

    def test_disabled_provider_is_not_initialized(self):
        self.g.convars["lyre_bridge:provider:server:sample:disabled"] = "primary"
        self.assertEqual(self.resolve()["__name"], "fallback")
        self.assertEqual(self.g.attempts, 0)
