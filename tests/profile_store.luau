local fs = require('@lune/fs')
-- Run from the repository root. DataStores are mocked; no network access.
local root = ''
local function read(relative)
 local code, err = loadstring(fs.readFile(root .. relative))
 assert(code,err)
 return code
end
local config = read('src/shared/Config.luau')()
local economy = read('src/shared/Economy.luau')()
local calls = 0
local data
local fail = false
local datastore = {}
function datastore:UpdateAsync(key, transform)
 calls += 1
 if fail then error('DataStore denied') end
 local nextData = transform(data)
 if nextData ~= nil then data = nextData end
 return nextData
end
local services = {
 HttpService = {GenerateGUID = function() return 'test-server-session' end},
 DataStoreService = {GetDataStore = function() calls += 1; return datastore end},
}
local chunk = read('src/server/ProfileStore.luau')
setfenv(chunk, setmetatable({
 game = {JobId = '', GetService = function(_, name) return services[name] end},
 warn = function() end,
}, {__index = getfenv()}))
local store = chunk()
local player = {UserId = 42}
local disabled = store.load(player, config, economy)
assert(not disabled.persistent and calls == 0)
assert(not store.save(player, disabled, true) and calls == 0)
print('PASS disabled persistence makes no DataStore calls')
config.PersistenceEnabled = true
local state = store.load(player, config, economy)
assert(state.persistent and state.profile.cash == config.StartingCash)
assert(data._session == state._session and data._expiresAt > os.time())
assert(string.find(state._session, 'test-server-session:', 1, true) == 1)
state.profile.cash = 321
assert(store.save(player, state, false) and data.cash == 321)
assert(data._economy == nil and data._config == nil)
print('PASS load claims lease and save copies public profile')
local overlap = store.load(player, config, economy)
assert(not overlap.persistent and overlap._session ~= state._session)
assert(data._session == state._session)
print('PASS overlapping rejoins in one server cannot share a lease')
fail = true
assert(not store.save(player, state, false) and state.persistent and data.cash == 321)
local fallback = store.load(player, config, economy)
assert(not fallback.persistent and type(fallback.warning) == 'string')
fail = false
local before = calls
assert(not store.save(player, fallback, false) and calls == before and data.cash == 321)
assert(store.save(player, state, false) and data.cash == 321)
print('PASS failed load cannot overwrite stored data; transient save failure permits retry')
data._session = 'another-server'
data._expiresAt = os.time() + 180
local locked = store.load(player, config, economy)
assert(not locked.persistent and type(locked.warning) == 'string')
assert(not store.save(player, state, false) and not state.persistent and data.cash == 321)
print('PASS live foreign lease blocks load and stale owner cannot save')
data._expiresAt = os.time() - 1
local resumed = store.load(player, config, economy)
assert(resumed.persistent and resumed.profile.cash == 321)
assert(store.save(player, resumed, true) and not resumed.persistent)
assert(data._session == nil and data._expiresAt == nil and data.cash == 321)
print('PASS expired lease recovers stored profile and clean release clears lease')
