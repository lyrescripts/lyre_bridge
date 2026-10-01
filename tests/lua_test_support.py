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

"""Load real bridge Lua with controlled FiveM and framework boundaries."""

from pathlib import Path
import unittest

from lupa.lua54 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]

SETUP = """
providers, exported, printed = {}, {}, {}
activeResources, convars, clockTime, invokingResource = {}, {}, 0, 'test_consumer'
LyreBridge = {registerProvider=function(side, module, name, priority)
    local provider = {}
    providers[side .. ':' .. module .. ':' .. name] = provider
    return provider
end}
bridge = {core={}, custom={}, config={}}
function bridge.core.isStarted(name) return activeResources[name] == true end
bridge.core.isAvailable = bridge.core.isStarted
function GetConvar(name, fallback) return convars[name] or fallback end
function GetGameTimer() return clockTime end
function GetInvokingResource() return invokingResource end
function GetCurrentResourceName() return 'lyre_bridge' end
function IsDuplicityVersion() return true end
function IsPlayerAceAllowed() return false end
function RegisterNetEvent(...) end
function AddEventHandler(...) end
function print(...) printed[#printed + 1] = {...} end
exports = setmetatable({}, {__call=function(_, name, callback) exported[name] = callback end})
function cfxReference(callback)
    return setmetatable({__cfx_functionReference='test-reference'}, {
        __call=function(_, ...) return callback(...) end,
        __index=function() error('Cannot index a funcref') end,
    })
end
nativePlayers = {[1]={PlayerData={source=1,citizenid='OWNER1',charinfo={},money={},metadata={},
    job={name='police',label='Police',grade={level=3,name='Sergeant'},onduty=true},
    gang={name='ballas',label='Ballas',grade={level=2},isboss=false},items={}},Functions={}}}
qbCore = {Functions={GetPlayer=function(id) return nativePlayers[id] end}}
exports['qb-core'] = {GetCoreObject=function() return qbCore end}
exports.qbx_core = {
    GetPlayer=function(_,id) return nativePlayers[id] end,
    GetQBPlayers=function() return nativePlayers end,
}
esxPlayers = {[1]={source=1,identifier='ESX1',job={name='police',grade=3,grade_label='Sergeant'}}}
esxPlayers[1].getJob=function() return esxPlayers[1].job end
esxPlayers[1].getName=function() return 'Test Player' end
exports.es_extended = {getSharedObject=function() return {
    GetPlayerFromId=function(id) return esxPlayers[id] end,
} end}
"""


class LuaTestCase(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(SETUP)
        self.g = self.lua.globals()

    def load(self, relative):
        self.lua.execute((ROOT / relative).read_text(encoding="utf-8-sig"), name="@" + relative)

    def provider(self, side, module, name):
        self.load(f"bridges/{side}/{module}/{name}.lua")
        provider = self.g.providers[f"{side}:{module}:{name}"]
        if provider.init:
            provider.init(provider)
        return provider

    def run_lua(self, code):
        return self.lua.execute(code)
