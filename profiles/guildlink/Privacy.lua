local ADDON, ns = ...
-- A compatibility facade for the upstream UI. No Battle.net API or message handlers.
local A = { TEAM_GRACE = 0 }
ns.Accord = A
function A.ReadTag() return nil, "disabled" end
function A.AccountKey() return nil end
function A.TeamMember() return false end
function A.TeamShown() return false end
function A.TeamRevealed() return false end
function A.Ask() return false end
function A.Check() end
function A.Count() return 0 end
function A.Groups() return {} end
function A.Rows() return {} end
function A.CodesOf() return {} end
function A.TeamLines() return {} end
function A.ProfileLines() return {} end
function A.LockedLines() return {} end
function A.HashOf() return nil end
function A.TagOf() return nil end
function A.PrevHashOf() return nil end
function A.Frame() return nil end
function A.Hide() end
function A.Stats() return {} end
function A.StatusLine() return "BattleTag collection disabled; in-game sharing choices only" end
function A.Show() if ns.Consent and ns.Consent.Show then ns.Consent.Show() end end
function A.Slash() A.Show() end
function A.Accept() return false, "not-required" end
