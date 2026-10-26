local ADDON, ns = ...

-- Edit this file before sharing the SAME build with all three guilds, then /reload.
-- Empty lists intentionally admit nobody. Do not put placeholder guild names here.
ns.FederationConfig = {
    network = "BS3GUILD01", -- Keep identical on every member's installation.
    guilds = { Alliance = {}, Horde = {} },
    -- Example: Alliance = { "First Guild", "Second Guild", "Third Guild" }
    realms = {}, -- Optional normalized realm allowlist, e.g. { "ClassicBetaPvP" }.
    officerRank = 1, -- WoW rank index: 0 = guild master, 1 = first officer rank.
    -- Optional alliance-wide coordinator; leave empty for equal, independent guilds.
    -- Alliance = { name = "First Surname", realm = "ClassicBetaPvP", guild = "First Guild" }
    coordinators = {},
}
