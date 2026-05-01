exports("BridgeVersion", function()
    return LyreBridge.versionString()
end)

CreateThread(function()
    Wait(0)
    LyreBridge.log("debug", "Client core ready.", {
        resource = GetCurrentResourceName(),
        version = LyreBridge.version,
    })
end)
