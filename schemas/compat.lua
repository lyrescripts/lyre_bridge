LyreBridge = LyreBridge or {}
LyreBridge.SQL_COMPAT = LyreBridge.SQL_COMPAT or {}

LyreBridge.SQL_COMPAT.licenseSeeds = {
    lyre_boatschool = {
        { type = "boat", label = "Boat License" },
    },
    lyre_drivingschool = {
        { type = "drive", label = "Drivers License" },
        { type = "drive_bike", label = "Motorcycle License" },
        { type = "drive_truck", label = "Commercial Drivers License" },
    },
    lyre_flightschool = {
        { type = "fly_plane", label = "Pilot License" },
        { type = "fly_heli", label = "Helicopter License" },
    },
}

LyreBridge.SQL_COMPAT.skipPreparedLicenseBlocks = {
    lyre_boatschool = true,
    lyre_drivingschool = true,
    lyre_flightschool = true,
}
