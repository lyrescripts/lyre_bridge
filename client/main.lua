exports("BridgeVersion", function()
    return LyreBridge.versionString()
end)

exports("GetActiveBridgeInfo", function(resourceName, side)
    return LyreBridge.getActiveBridgeInfo(resourceName, side)
end)

CreateThread(function()
    Wait(0)
    LyreBridge.log("debug", "Client core ready.", {
        resource = GetCurrentResourceName(),
        version = LyreBridge.version,
    })
end)
