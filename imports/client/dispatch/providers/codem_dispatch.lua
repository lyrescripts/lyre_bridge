LyreBridge.registerProvider("client", "dispatch", {
    name = "codem-dispatch",
    resource = "codem-dispatch",
    priority = 160,
    send = function(self, context)
        local payload = context.payload

        exports["codem-dispatch"]:CustomDispatch({
            type = payload.title,
            header = payload.title,
            text = payload.message,
            code = payload.code,
            coords = payload.coords,
            job = payload.jobs,
            dispatchJobs = payload.jobs,
        })

        return true, true
    end,
})
