local provider = LyreBridge.registerProvider("server", "society", "qb", 20)

---Active when either `qb-management` or `qb-banking` is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qb-management") or bridge.core.isStarted("qb-banking")
end

---Read the society's current cash balance.
---@param jobName string
---@return integer
function provider:getMoney(jobName)
    local resource = bridge.core.isStarted("qb-banking") and "qb-banking" or "qb-management"
    return exports[resource]:GetAccountBalance(jobName) or 0
end

---Credit the society account.
---@param jobName string
---@param amount integer
---@return boolean
function provider:addMoney(jobName, amount)
    local resource = bridge.core.isStarted("qb-banking") and "qb-banking" or "qb-management"
    return exports[resource]:AddMoney(jobName, amount) ~= false
end

---Debit the society account.
---@param jobName string
---@param amount integer
---@return boolean
function provider:removeMoney(jobName, amount)
    local resource = bridge.core.isStarted("qb-banking") and "qb-banking" or "qb-management"
    return exports[resource]:RemoveMoney(jobName, amount) ~= false
end
