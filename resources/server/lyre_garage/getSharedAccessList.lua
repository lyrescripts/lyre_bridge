LyreBridge.registerCustomResourceFunction("lyre_garage", "getSharedAccessList", function(plate)
    -- Return the list of identifiers that have shared access to this vehicle.
    -- Example: return { "char1:abc...", "char1:def..." }
    return {}
end)
