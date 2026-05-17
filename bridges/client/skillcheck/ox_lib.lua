local provider = LyreBridge.registerProvider("client", "skillcheck", "ox_lib", 10)

---Active when the `ox_lib` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("ox_lib")
end

---Run a skill check minigame and resolve once it ends.
---@param difficulty BridgeSkillCheckDifficulty Difficulty preset or descriptor accepted by `lib.skillCheck`.
---@param inputs? string[] Valid key chars (defaults to `{ "e" }`).
---@return boolean passed True when the player passed every check.
function provider:run(difficulty, inputs)
    return exports.ox_lib:skillCheck(difficulty, inputs)
end
