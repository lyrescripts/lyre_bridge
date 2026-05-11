LyreBridge.registerCustomResourceFunction("lyre_garage", "SaveVehicleDeformation", function(vehicle, properties)
    -- Optional integration with a deformation script. Add `properties.deformation = ...`
    -- here and return the modified properties to persist deformation data.
    -- Example: properties.deformation = exports.VehicleDeformation:GetVehicleDeformation(vehicle)
    return properties
end)
