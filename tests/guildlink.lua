-- Real packaged modules in the inherited strict Forever model; no replacement of feature logic.
local M = assert(loadfile("tests/gamepad.lua"))("--debug")
local passed, failed = 0, 0
local function eq(a, b, note) assert(a == b, (note or "") .. " expected " .. tostring(b) .. ", got " .. tostring(a)) end
local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then passed = passed + 1; print("PASS " .. name)
    else failed = failed + 1; print("FAIL " .. name .. ": " .. tostring(err)) end
end
local function Config()
    return { network = "BS3GUILD01", guilds = { Alliance = { "First Guild", "Second Guild", "Third Guild" }, Horde = { "Horde Guild" } }, realms = {}, officerRank = 1, coordinators = {} }
end
local function Clean(C)
    eq(#C.loadErrors, 0, C.loadErrors[1])
    local errors = M.Errors(C)
    eq(#errors, 0, errors[1])
    eq(#C.isolatedErrors, 0, C.isolatedErrors[1])
    eq(next(C.unmodelled), nil, "unmodelled client API")
end
local function Boot(config, pad, identity)
    identity = identity or {}
    local C, ns = M.Boot({ gamepad = pad, federation = config, setup = function(c)
        c.units.player.guild = identity.guild or "First Guild"
        c.units.player.name = identity.name or "Tester"
        c.roster[1][1] = c.units.player.name .. "-Realm"
        c.env.BNGetInfo = function() error("GuildLink must not read BattleTags") end
    end })
    M.Login(C, 80)
    Clean(C)
    return C, ns
end

test("shipped empty configuration boots without traffic or BattleTag reads", function()
    local C, ns = Boot(nil, false)
    eq(ns.IsMember(), false)
    eq(#C.sent, 0)
    eq(ns.Who.Search(false), false)
    assert(ns.Federation.Status():find("Setup needed", 1, true))
    ns.UI.Toggle(); C.Advance(1); Clean(C)
end)
test("configured client loads every shipped module and main UI", function()
    local C, ns = Boot(Config(), false)
    eq(ns.IsMember(), true)
    eq(ns.PREFIX, "GLBS3GUILD01")
    eq(ns.Comm.ChannelSpec(), "GLBS3GUILD01A")
    ns.UI.Toggle(); C.Advance(1)
    ns.Accord.Show(); C.Advance(1)
    Clean(C)
    assert(rawget(C.env, "GuildLinkDB"))
    eq(rawget(C.env, "OlympusDB"), nil)
    eq(rawget(C.env, "SLASH_GUILDLINK1"), "/guildlink")
    eq(rawget(C.env, "SLASH_GUILDLINK2"), "/gl")
end)
test("exact configured names only, faction separation, no upstream admission", function()
    local C, ns = Boot(Config())
    eq(ns.IsFederation("FIRST GUILD"), true)
    for _, name in ipairs({ "First Guild Extra", "FirstGuild", "Olympus", "OLYMPIAN", "Mudhutters", "GuildLink", "First Guild|" }) do
        eq(ns.IsFederation(name), false, name)
    end
    eq(ns.IsFederation("Horde Guild"), false)
    ns.faction = "Horde"
    eq(ns.IsFederation("First Guild"), false)
    eq(ns.IsFederation("Horde Guild"), true)
    eq(ns.Comm.ChannelSpec(), "GLBS3GUILD01H")
end)
test("invalid config fails closed and does not send", function()
    for _, mutation in ipairs({
        function(c) c.network = "bad~network" end,
        function(c) c.guilds.Alliance = { 'Bad"Guild' } end,
        function(c) c.guilds.Alliance = { "First Guild", "first guild" } end,
        function(c) c.officerRank = 1.5 end,
        function(c) c.realms = { "Bad Realm" } end,
        function(c) c.realms = "not-a-list" end,
    }) do
        local config = Config(); mutation(config)
        local C, ns = Boot(config)
        eq(ns.Federation.Ready(), false); eq(ns.IsMember(), false); eq(#C.sent, 0)
    end
end)
test("realm allowlist refuses other realm groups", function()
    local config = Config(); config.realms = { "OtherRealm" }
    local C, ns = Boot(config)
    eq(ns.IsMember(), false); eq(#C.sent, 0)
    ns.realm = "OtherRealm"
    eq(ns.IsFederation("First Guild"), true)
end)
test("no inherited author, king, treasurer, council, steward or signing authority", function()
    local C, ns = Boot(Config())
    eq(ns.Workshop.IsAuthorName("Faladoriel Skylance-ClassicBetaPvP"), false)
    eq(ns.IsKingCharacter("Asmongold Asmongler-ClassicBetaPvP"), false)
    eq(ns.IsKingCharacter("Duskmonkey Boneback-Realm"), false)
    eq(ns.IsTreasurerCharacter("Pyralis Ashandar-ClassicBetaPvP"), false)
    ns.rdb.council = { names = { attacker = true } }
    eq(ns.IsHighCouncillor("Attacker-Realm"), false)
    eq(ns.IsSteward("Attacker-Realm"), false)
    eq(ns.Sign.Verify("anything", string.rep("a", 512)), false)
    eq(ns.KingCharacter(), nil)
    eq(ns.Accord.ReadTag(), nil); eq(ns.Accord.TeamMember(), false)
    eq(ns.Link.BotReady(), false); eq(ns.LINK_SITE, "")
end)
test("optional coordinator requires admitted guild, exact character and realm", function()
    local config = Config()
    config.coordinators.Alliance = { name = "Leader Person", realm = "Realm", guild = "First Guild" }
    local C, ns = Boot(config)
    eq(ns.IsKingCharacter("Leader Person-Realm"), true)
    eq(ns.IsKingCharacter("Leader Person-OtherRealm"), false)
    eq(ns.IsKingCharacter("Leader Person Extra-Realm"), false)
    eq(ns.IsKingGuild("First Guild"), true)
    eq(ns.IsKingGuild("Second Guild"), false)
    config.coordinators.Alliance.guild = "Unlisted"
    eq(ns.IsKingCharacter("Leader Person-Realm"), false)
end)
test("recruitment searches all three configured names", function()
    local C, ns = Boot(Config())
    eq(ns.Who.QUERY, 'g-"First Guild"')
    eq(#ns.Who.VARIANTS, 2)
    eq(ns.Who.VARIANTS[1], "Second Guild"); eq(ns.Who.VARIANTS[2], "Third Guild")
end)
test("same sealed key stays separate from upstream and other networks", function()
    local C, ns = Boot(Config())
    ns.rdb.realmKey = "a-shared-test-key"
    local one, key = ns.Comm.ChannelSpec()
    eq(key, "a-shared-test-key")
    assert(one:find("GLBS3GUILD01A", 1, true) == 1)
    local other = Config(); other.network = "DIFFERENT1"
    local D, ds = Boot(other); ds.rdb.realmKey = key
    assert(ds.Comm.ChannelSpec() ~= one)
end)
test("census accepts configured sister guild and excludes unrelated report", function()
    local C, ns = Boot(Config())
    local before = ns.Data.Summary().total
    local report = { guild = "Second Guild", total = 10, online = 3, leader = "Otherleader-Realm", leaderOnline = true,
        zones = {}, classes = {}, levels = {}, ranks = {}, officers = {}, users = 1, faction = "Alliance", from = "Realm", home = "Realm" }
    local wire = ns.Codec.EncodeReport(report)
    assert(ns.Data.Receive(ns.Data.DecodeReport(wire, "Reporter-Realm"), "Reporter-Realm"))
    eq(ns.Data.Summary().total, before + 10)
    report.guild = "Unlisted"
    ns.Data.Receive(ns.Data.DecodeReport(ns.Codec.EncodeReport(report), "Outsider-Realm"), "Outsider-Realm")
    eq(ns.Data.Summary().total, before + 10)
    Clean(C)
end)
test("shared chat uses the isolated wire and arrives in a sister guild", function()
    local C, ns = Boot(Config())
    local D, ds = Boot(Config(), false, { name = "Friend", guild = "Second Guild" })
    ns.Channels.SetChatOn(true); ds.Channels.SetChatOn(true)
    ns.db.chatWarned = { A = true }
    eq(ns.Channels.CanUse("C"), false, "ordinary member cannot send officer chat")
    local ok, why = ns.Channels.Send("A", "Hello sister guild")
    eq(ok, true, why)
    C.Advance(6)
    local delivered = 0
    for _, message in ipairs(C.sent) do
        if message[2]:sub(1, 3) == "M1~" then
            eq(message[1], ds.PREFIX)
            eq(message[3], "CHANNEL")
            D.Fire("CHAT_MSG_ADDON_LOGGED", message[1], message[2], "CHANNEL", "Tester-Realm", nil, nil, D.channels[ds.CHANNEL], ds.CHANNEL)
            delivered = delivered + 1
        end
    end
    assert(delivered > 0, "the real communication queue must deliver a chat message")
    local history = ds.Channels.History("A")
    eq(history[#history].text, "Hello sister guild")
    Clean(C); Clean(D)
end)
test("gamepad login and both mode switches retain client protections", function()
    for _, pad in ipairs({ false, true }) do
        local C, ns = Boot(Config(), pad)
        for _, mode in ipairs({ pad, not pad, pad }) do
            C.Switch(mode); C.Advance(2)
            ns.UI.Toggle(); C.Advance(1)
            ns.UI.Toggle(); C.Advance(1)
            Clean(C)
        end
        M.Check(C.ledger, "GuildLink mode switches")
    end
end)
print(("%d passed, %d failed"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
