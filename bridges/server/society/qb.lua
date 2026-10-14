local provider = LyreBridge.registerProvider("server", "society", "qb", 20)

---Active when the QB society account provider is running.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qb-banking")
end

---Read the society's current cash balance.
---@param jobName string
---@return integer
function provider:getMoney(jobName)
    return exports["qb-banking"]:GetAccountBalance(jobName) or 0
end

---Credit the society account.
---@param jobName string
---@param amount integer
---@return boolean
function provider:addMoney(jobName, amount)
    return exports["qb-banking"]:AddMoney(jobName, amount) ~= false
end

---Debit the society account.
---@param jobName string
---@param amount integer
---@return boolean
function provider:removeMoney(jobName, amount)
    return exports["qb-banking"]:RemoveMoney(jobName, amount) ~= false
end
