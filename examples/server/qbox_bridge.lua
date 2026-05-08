-- Example: add a custom Qbox server bridge candidate.
--[[
_G.bridge = _G.bridge or {}
_G.bridge.QBOX = _G.bridge.QBOX or {}

function _G.bridge.QBOX.autoDetect()
    return LyreBridge.isStarted("qbx_core")
end

function _G.bridge.QBOX:init()
    self.object = exports["qbx_core"]
end
]]
