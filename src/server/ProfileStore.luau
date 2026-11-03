-- Optional DataStore persistence. Failed/locked loads stay strictly session-only.
local Store = {}
local LEASE_SECONDS = 180
local serverSession
local loadSequence = 0

local function sessionId()
    if not serverSession then
        local ok, id = pcall(function()
            return game:GetService("HttpService"):GenerateGUID(false)
        end)
        local candidate = if ok and type(id) == "string" and id ~= "" then id else game.JobId
        assert(type(candidate) == "string" and candidate ~= "", "No unique session ID available")
        serverSession = candidate
    end
    return serverSession
end

function Store.load(player, config, economy)
    local state = {
        profile = economy.newProfile(config),
        persistent = false,
        _config = config,
        _economy = economy,
    }
    if not config.PersistenceEnabled then
        return state
    end

    local locked = false
    local ok, stored = pcall(function()
        loadSequence += 1
        state._session = sessionId() .. ":" .. tostring(loadSequence)
        state._key = "player_" .. tostring(player.UserId)
        state._store = game:GetService("DataStoreService"):GetDataStore(config.DataStoreName)
        return state._store:UpdateAsync(state._key, function(previous)
            locked = type(previous) == "table"
                and type(previous._session) == "string"
                and previous._session ~= state._session
                and type(previous._expiresAt) == "number"
                and previous._expiresAt > os.time()
            if locked then
                return nil
            end
            local profile = economy.sanitizeProfile(config, previous)
            profile._session = state._session
            profile._expiresAt = os.time() + LEASE_SECONDS
            return profile
        end)
    end)

    if not ok or type(stored) ~= "table" or stored._session ~= state._session then
        state.warning = if locked
            then "Your save is open in another server. This visit will not save progress."
            else "Saving is unavailable. This visit will not save progress."
        return state
    end

    state.profile = economy.sanitizeProfile(config, stored)
    state.persistent = true
    return state
end

function Store.save(player, state, release)
    if not state.persistent then
        return false
    end
    if state._saving then
        if not release then
            return false
        end
        local deadline = os.clock() + 8
        repeat
            task.wait(0.1)
        until not state._saving or os.clock() >= deadline
        if state._saving or not state.persistent then
            return false
        end
    end

    state._saving = true
    local lostLease = false
    local ok, result = pcall(function()
        -- Sanitation copies only the public profile, never internal state or Instances.
        local snapshot = state._economy.sanitizeProfile(state._config, state.profile)
        return state._store:UpdateAsync(state._key, function(previous)
            lostLease = type(previous) ~= "table" or previous._session ~= state._session
            if lostLease then
                return nil
            end
            if not release then
                snapshot._session = state._session
                snapshot._expiresAt = os.time() + LEASE_SECONDS
            end
            return snapshot
        end)
    end)
    state._saving = false

    if lostLease then
        state.persistent = false
        state.warning = "Your save moved to another server. Further progress here will not save."
        warn("Profile lease lost for user " .. tostring(player.UserId))
        return false
    end
    if not ok or type(result) ~= "table" then
        warn("Profile save failed for user " .. tostring(player.UserId))
        return false
    end
    if release then
        state.persistent = false
    end
    return true
end

return Store
