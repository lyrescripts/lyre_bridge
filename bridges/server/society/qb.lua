local provider = LyreBridge.registerProvider("server", "society", "qb", 20)

function provider:detect()
    return bridge.core:isStarted("qb-management") or bridge.core:isStarted("qb-banking")
end

function provider:getMoney(jobName)
    local resource = bridge.core:isStarted("qb-banking") and "qb-banking" or "qb-management"
    return exports[resource]:GetAccountBalance(jobName) or 0
end

function provider:addMoney(jobName, amount)
    local resource = bridge.core:isStarted("qb-banking") and "qb-banking" or "qb-management"
    return exports[resource]:AddMoney(jobName, amount) ~= false
end

function provider:removeMoney(jobName, amount)
    local resource = bridge.core:isStarted("qb-banking") and "qb-banking" or "qb-management"
    return exports[resource]:RemoveMoney(jobName, amount) ~= false
end
