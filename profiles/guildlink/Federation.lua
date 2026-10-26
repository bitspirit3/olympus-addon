local ADDON, ns = ...
local F = { errors = {} }
ns.Federation = F
local config = type(ns.FederationConfig) == "table" and ns.FederationConfig or {}
local guilds = { Alliance = {}, Horde = {} }
local lists = { Alliance = {}, Horde = {} }
local realms = {}
local function Reject(message) F.errors[#F.errors + 1] = message end
local function GuildName(name)
    if type(name) ~= "string" or name == "" or #name > 72 or name:find('[~=,:|%c"\\]') then return nil end
    if name ~= name:match("^%s*(.-)%s*$") or select(2, name:gsub("[^\128-\191]", "")) > 24 then return nil end
    return name:lower()
end
local network = config.network
if type(network) ~= "string" or #network < 6 or #network > 12 or not network:match("^[A-Z0-9]+$") then
    Reject("network must contain 6-12 uppercase letters or digits")
    network = "UNCONFIGURED"
end
for _, faction in ipairs({ "Alliance", "Horde" }) do
    local names = type(config.guilds) == "table" and config.guilds[faction] or nil
    if type(names) ~= "table" then Reject("guilds." .. faction .. " must be a list") else
        for _, name in ipairs(names) do
            local key = GuildName(name)
            if not key then Reject("Invalid guild name in " .. faction)
            elseif guilds[faction][key] then Reject("Duplicate guild: " .. name)
            else
                guilds[faction][key] = true
                lists[faction][#lists[faction] + 1] = name
            end
        end
    end
end
if type(config.realms) ~= "table" then Reject("realms must be a list") end
for _, realm in ipairs(type(config.realms) == "table" and config.realms or {}) do
    if type(realm) ~= "string" or realm == "" or realm:find("[%s%-%+|~%c]") then
        Reject("Realms must use normalized names without spaces or dashes")
    else realms[#realms + 1] = realm end
end
local officer = config.officerRank
if type(officer) ~= "number" or officer < 0 or officer > 9 or officer ~= math.floor(officer) then
    Reject("officerRank must be an integer from 0 through 9")
    officer = 1
end
function F.Ready() return #F.errors == 0 end
function F.RealmAllowed()
    if not F.Ready() then return false end
    if #realms == 0 then return true end
    local home = ns.realm or ns.CurrentRealm()
    for _, realm in ipairs(realms) do
        if ns.GroupOf(home) == ns.GroupOf(realm) then return true end
    end
    return false
end
function F.Guilds()
    local out = {}
    if F.RealmAllowed() then
        for _, name in ipairs(lists[ns.faction or "Alliance"] or {}) do out[#out + 1] = name end
    end
    return out
end
function F.Contains(name)
    local key = GuildName(name)
    return key ~= nil and F.RealmAllowed() and (guilds[ns.faction or "Alliance"] or {})[key] == true
end
function F.Coordinator()
    local c = type(config.coordinators) == "table" and config.coordinators[ns.faction or "Alliance"]
    if type(c) ~= "table" or not F.Contains(c.guild) then return nil end
    if type(c.name) ~= "string" or c.name == "" or c.name:find("[~|%c%-]") then return nil end
    if type(c.realm) ~= "string" or c.realm == "" or c.realm:find("[%s%-%+|~%c]") then return nil end
    if ns.GroupOf(ns.realm or ns.CurrentRealm()) ~= ns.GroupOf(c.realm) then return nil end
    return c
end
function F.Status()
    if not F.Ready() then return "Configuration error: " .. table.concat(F.errors, "; ") end
    local names = F.Guilds()
    if #names == 0 then return "Setup needed: add your exact guild names to GuildLink/Settings.lua, distribute the same file, then /reload." end
    return "GuildLink: " .. table.concat(names, ", ") .. ". Network: " .. network
end

ns.NAME = "GuildLink"
ns.PREFIX = "GL" .. network
ns.CHANNEL, ns.CHANNEL_HORDE = "GL" .. network .. "A", "GL" .. network .. "H"
ns.CAPTAIN_RANK = officer
ns.AUTHOR, ns.AUTHOR_REALM = "", ""
ns.TREASURER, ns.TREASURER_REALM, ns.TREASURER_CHARACTERS = "", "", {}
ns.KING_NAME, ns.KING_CHARACTER, ns.KING_GUILD = "Coordinator", {}, {}
ns.KING_REALM, ns.KING_REALM_HORDE = nil, nil
ns.APPROVED_BUILTIN, ns.REMOVED_BUILTIN = {}, {}
ns.IsFederation, ns.NamedOlympus, ns.IsApprovedGuild = F.Contains, F.Contains, F.Contains
function ns.ApprovedGuilds() return F.Guilds() end
function ns.ApprovedOnly() return false end
function ns.IsRemovedGuild() return false end
function ns.IsHighCouncillor() return false end
function ns.IsSteward() return false end
function ns.Stewards() return {} end
function ns.CouncilTitles() return nil end
function ns.IsTreasurer() return false end
function ns.IsTreasurerMail() return false end
function ns.IsTreasurerCharacter() return false end
function ns.LearnKingRealm() end
function ns.KingRealm() local c = F.Coordinator(); return c and c.realm end
function ns.KingCharacter() local c = F.Coordinator(); return c and c.name end
function ns.IsKingCharacter(name)
    local c = F.Coordinator()
    if not c or type(name) ~= "string" or ns.ShortName(name) ~= c.name then return false end
    local realm = ns.RealmOf(ns.FullName(name))
    return realm ~= nil and ns.GroupOf(realm) == ns.GroupOf(c.realm)
end
function ns.IsKingGuild(name)
    local c = F.Coordinator()
    return c ~= nil and type(name) == "string" and name:lower() == c.guild:lower()
end
function ns.KingGuildName() local c = F.Coordinator(); return c and c.guild end
function ns.KingName() local c = F.Coordinator(); return c and c.name or "Coordinator" end
-- Installation enables the census; optional chat/location sharing keeps upstream's opt-ins.
-- There is no BattleTag agreement, signing service or inherited central administrator.
function ns.AccordAccepted() return true end
ns.L.TITLE = "GuildLink"
ns.L.CHAN_ALL = "GuildLink"
ns.L.MEMBERS_ONLY = "Configured guild members only"
ns.L.MEMBERS_ONLY_HINT = "Use /guildlink setup for the guild list and configuration instructions."
ns.L.APPROVED_JOIN_HINT = "Guild membership is configured in Settings.lua; signed Olympus lists are not used."
ns.L.ACCORD_READ = "Privacy information"
ns.L.CONSENT_TITLE = "GuildLink: sharing choices"
ns.L.CONSENT_INTRO = "While you are in a configured guild, the addon exchanges census reports and guild presence messages inside the game. Census reports include member counts, levels, classes, ranks, leader and officer names, and top-level members. Optional sharing is controlled below. This build does not collect BattleTags or connect to Discord or a desktop Companion. %s"
ns.On("LOGIN", function() ns.Print(F.Status()) end)
