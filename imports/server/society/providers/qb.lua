local function getMoney(jobName)
    if LyreBridge.isStarted("qb-management") then
        return tonumber(exports["qb-management"]:GetAccount(jobName)) or 0
    end

    if LyreBridge.isStarted("qb-banking") then
        return tonumber(exports["qb-banking"]:GetAccountBalance(jobName)) or 0
    end

    return tonumber(MySQL.scalar.await("SELECT amount FROM management_funds WHERE job_name = ?", { jobName })) or 0
end

local function removeMoney(jobName, amount)
    if LyreBridge.isStarted("qb-management") then
        return exports["qb-management"]:RemoveMoney(jobName, amount) ~= false
    end

    if LyreBridge.isStarted("qb-banking") then
        return exports["qb-banking"]:RemoveMoney(jobName, amount, "Society payment") ~= false
    end

    local affected = MySQL.update.await("UPDATE management_funds SET amount = amount - ? WHERE job_name = ? AND amount >= ?", {
        amount,
        jobName,
        amount,
    })
    return affected and affected > 0
end

LyreBridge.registerProvider("server", "society", {
    name = "qb",
    priority = 110,
    isAvailable = function(self, context)
        return context.framework == "QBCORE" or context.framework == "QBOX"
    end,
    getMoney = function(self, context)
        return true, getMoney(context.jobName)
    end,
    removeMoney = function(self, context)
        return true, removeMoney(context.jobName, context.amount)
    end,
})
