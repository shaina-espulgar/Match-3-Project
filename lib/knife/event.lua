local Event = {}

Event.handlers = {}

local function remove (self)
    if not self.isRegistered then
        return self
    end
    if self.prevHandler then
        self.prevHandler.nextHandler = self.nextHandler
    end
    if self.nextHandler then
        self.nextHandler.prevHandler = self.prevHandler
    end
    if Event.handlers[self.name] == self then
        Event.handlers[self.name] = self.nextHandler
    end
    self.prevHandler = nil
    self.nextHandler = nil
    self.isRegistered = false

    return self
end

local function register (self)
    if self.isRegistered then
        return self
    end
    self.nextHandler = Event.handlers[self.name]
    if self.nextHandler then
        self.nextHandler.prevHandler = self
    end
    Event.handlers[self.name] = self
    self.isRegistered = true

    return self
end

local function Handler (name, callback)
    return {
        name = name,
        callback = callback,
        isRegistered = false,
        remove = remove,
        register = register
    }
end

function Event.on (name, callback)
    return register(Handler(name, callback))
end

function Event.dispatch (name, ...)
    local handler = Event.handlers[name]

    while handler do
        if handler.callback(...) == false then
            return handler
        end
        handler = handler.nextHandler
    end
end

local function isCallable (value)
    return type(value) == 'function' or
        getmetatable(value) and getmetatable(value).__call
end

local function hookDispatcher (t, key)
    local original = t[key]

    if isCallable(original) then
        t[key] = function (...)
            original(...)
            return Event.dispatch(key, ...)
        end
    else
        t[key] = function (...)
            return Event.dispatch(key, ...)
        end
    end
end

function Event.hook (t, keys)
    if keys then
        for _, key in ipairs(keys) do
            hookDispatcher(t, key)
        end
    else
        for key in pairs(t) do
            hookDispatcher(t, key)
        end
    end
end

return Event
