LyreBridge.registerCustomResourceFunction("lyre_illegalmissions", "onMissionEnd", function(missionType, success, teamMembers)
    -- Custom logic when an illegal mission ends. The return value is ignored, so this
    -- hook only ever adds behaviour on top of the built-in mission cleanup.
    -- missionType: string (e.g. "gofast", "atm", "cartheft", ...)
    -- success: boolean
    -- teamMembers: table of server ids
end)
