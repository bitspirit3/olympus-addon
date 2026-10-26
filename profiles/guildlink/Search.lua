local ADDON, ns = ...
-- Refresh when the faction/realm are resolved at login, and after learned realm links change.
local signature
local function Refresh()
    local names = ns.Federation.Guilds()
    local nextSignature = table.concat(names, "\0")
    if nextSignature == signature then return end
    signature = nextSignature
    ns.Who.QUERY = names[1] and ('g-"%s"'):format(names[1]) or 'g-"GuildLinkNotConfigured"'
    ns.Who.VARIANTS = {}
    for i = 2, #names do ns.Who.VARIANTS[#ns.Who.VARIANTS + 1] = names[i] end
end
Refresh()
ns.On("INIT", Refresh)
ns.On("LOGIN", Refresh)
ns.On("DATA_CHANGED", Refresh)
