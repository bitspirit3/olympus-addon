local ADDON, ns = ...
-- These replacements run after all feature modules and before ADDON_LOADED / PLAYER_LOGIN.
function ns.Recruit.Roast()
    return "Welcome to GuildLink", ns.Federation.Status()
end
ns.L.ROAST_GUILD_SUB = "Join one of the configured guilds to use the shared census."
ns.L.ROAST_NOGUILD_SUB = ns.L.ROAST_GUILD_SUB
ns.L.KING = "Coordinator"
ns.L.KING_TAB = "Coordinator"
-- No caller can enable an Olympus bridge by installing its sidecar beside this build:
-- all exported names and SavedVariables are separately namespaced by the builder.
