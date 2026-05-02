-- Example: opt a resource into a custom Qbox client bridge.
--[[
_G.bridge = _G.bridge or {}
_G.bridge.QBOX = _G.bridge.QBOX or {}

function _G.bridge.QBOX.autoDetect()
    return GetResourceState("qbx_core") == "started"
end

function _G.bridge.QBOX:init()
    self.object = exports["qbx_core"]
end
]]
