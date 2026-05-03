-- Example: add an adapter-specific target helper.
--[[
CreateThread(function()
    while not bridge do
        Wait(0)
    end

    function bridge:addInspectTarget(entity, label, onSelect)
        return self:targetAddLocalEntity(entity, {
            label = label,
            icon = "fa-solid fa-magnifying-glass",
            onSelect = onSelect,
        })
    end
end)
]]
