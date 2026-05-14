LyreBridge.modules = {
    server = {
        mysql = {
            "query", "single", "scalar", "update", "insert", "prepare", "rawExecute", "transaction",
        },
        players = {
            "getPlayerFromId", "getPlayerFromIdentifier", "getIdFromIdentifier",
            "getOnlinePlayers", "getOnlinePlayersByJob", "getPlayersInZone",
            "revive", "clearDeathStatus", "updateOfflinePlayerAccount",
        },
        vehicles = {
            "generateRandomPlate",
        },
        vehicle_storage = {
            "getTableName", "exists", "getOwner", "isOwnedBy", "setOwner",
            "getProperties", "setProperties", "getInfo", "getByOwner",
            "create", "delete", "renamePlate",
        },
        inventory = {
            "addItem", "removeItem", "getItemCount", "hasItem", "canCarryItem",
            "addAmmo", "setItemMetadata", "getItemBySlot", "supportsMetadata",
        },
        usable_items = {
            "register",
        },
        society = {
            "getMoney", "addMoney", "removeMoney",
        },
        dispatch = {
            "send",
        },
    },
    client = {
        notifications = {
            "show", "help",
        },
        players = {
            "getData", "getIdentifier", "getName", "getJob", "getGang",
            "isOnJobDuty", "isOnGangDuty", "getAccount",
            "revive", "clearDeathStatus",
        },
        target = {
            "addLocalEntity", "removeLocalEntity", "addSphereZone", "removeZone",
        },
        inventory = {
            "hasItem",
        },
        vehicles = {
            "getProperties", "applyProperties",
        },
        vehicle_keys = {
            "give", "remove",
        },
        fuel = {
            "get", "set",
        },
        dispatch = {
            "send",
        },
        progress = {
            "run",
        },
    },
}
