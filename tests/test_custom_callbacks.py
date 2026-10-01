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

"""Custom hooks accept CFX references and remain isolated by invoking resource."""

from lupa.lua54 import LuaError

from lua_test_support import LuaTestCase


class CustomCallbackTests(LuaTestCase):
    def setUp(self):
        super().setUp()
        self.load("engine/custom.lua")

    def test_cfx_callback_registers_and_forwards_arguments_and_return_value(self):
        self.run_lua("bridge.custom.register('sum',cfxReference(function(a,b) return a+b end))")
        self.assertTrue(self.g.bridge.custom.has("sum"))
        self.assertEqual(self.g.bridge.custom.call("sum", 3, 4), 7)

    def test_local_lua_callbacks_still_work(self):
        self.run_lua("bridge.custom.register('localHook',function() return 'local' end)")
        self.assertEqual(self.g.bridge.custom.call("localHook"), "local")

    def test_plain_tables_and_forged_non_callable_references_are_rejected(self):
        for code in ("{}", "{__cfx_functionReference='forged'}", "false", "nil"):
            with self.subTest(value=code), self.assertRaises(LuaError):
                self.run_lua("bridge.custom.register('invalid'," + code + ")")
        self.assertFalse(self.g.bridge.custom.has("invalid"))

    def test_resource_identity_controls_lookup(self):
        self.run_lua("bridge.custom.register('owned',cfxReference(function() return true end))")
        self.g.invokingResource = "other_consumer"
        self.assertFalse(self.g.bridge.custom.has("owned"))
        self.assertIsNone(self.g.bridge.custom.call("owned"))
        self.g.invokingResource = "test_consumer"
        self.assertTrue(self.g.bridge.custom.call("owned"))

    def test_empty_names_remain_invalid(self):
        with self.assertRaises(LuaError):
            self.run_lua("bridge.custom.register('',function() end)")
