# GuildLink for WoW Forever

An independent build profile of Olympus for a small group of sister guilds.
Working title: GuildLink. Version: 0.1.0-alpha1. Based on Olympus 1.3.2.

## Included

- Shared guild census: members, online counts, average levels, leaders, officers and vacancies.
- Guild and member views, recruiting requests, guild charters and inactive-member views.
- Shared member/officer/leader chats, with the original opt-in and rate limits.
- Guild operations, groups, agenda and announcements using the existing permissions.
- Optional location/layer sharing and map views, with the existing privacy choices.
- Original client compatibility and gamepad protections. Optional arena UI is bundled because
  the core references it; upstream's excluded wagering modules remain excluded.

The main source stays in Olympus/ so upstream fixes and its regression tests can still be used.
Build the customized addon with `python scripts/build-guildlink.py --output dist/guildlink`.
Use a new output directory for each build. Install the generated GuildLink folders, NOT Olympus/.

## Configure before playing

1. Edit `profiles/guildlink/Settings.lua` before building, or `GuildLink/Settings.lua` after unpacking.
2. Put the exact names into the Alliance or Horde guild list. Empty lists admit nobody. Names
   compare case-insensitively, with no fuzzy Olympus matching or implicit admission of your own guild.
3. Optionally restrict realms with normalized realm names. Leave realms empty while undecided;
   the existing realm-group system and faction separation still apply.
4. Keep the same network ID and settings on all installations. A different network means a separate
   prefix, public channel and sealed channel. It is isolation, not authentication or encryption.
5. Optional: name one coordinator by character name, realm and one of the admitted guilds. This
   enables the inherited alliance-wide coordinator features. Empty means no central administrator;
   guild masters and officers retain their existing guild-scoped tools.
6. Copy `GuildLink` and `GuildLink_Arena` into the client's `Interface/AddOns` directory and restart.
   After a settings-only edit, `/reload` is sufficient. Open `/guildlink` (alias `/gl`).

`/gl setup` explains the active configuration. `/gchat message` sends shared member chat;
`/glc message` is officer chat and `/gll message` is leader chat. Enable chats in `/gl privacy`.
`/gl status`, `/gl talk`, `/gl lfg`, and `/gl week` retain their upstream functions.

## Privacy and authority

No paid API, server, Discord bot or Companion is required. This build has separate addon folders,
SavedVariables, message prefixes, channel names and slash commands. It does not collect or send
BattleTags, and it does not accept the upstream author's signed lists. No inherited King, author,
treasurer, councillor or steward gets privileges. The desktop Companion bridge is not packaged.
Chat and roster information travel through WoW's addon messaging. Optional location sharing stays
opt-in. Remote census reports remain observations by other clients, not server-certified identities;
this profile does not turn those reports into stronger authentication.

## Scope and testing

Guild names, faction, realm and coordinator have not been supplied yet. This is an alpha package,
not a claim of a successful live Forever test. Inherited interface IDs: 11509, 16001, 20506.
The exact current Forever client still needs an in-game check.

Before rollout, use the same configuration on at least two clients in different configured guilds:
- Login, open `/gl`, verify no Lua errors and no Olympus channel is joined.
- Wait several minutes for census reports; compare online/member totals with each native roster.
- Enable chat on both; test `/gchat` in both directions and officer/leader restrictions.
- Test recruitment, guild events and opt-in map/layer sharing.
- Log out one reporter; verify another takes over and stale reports stop counting as online.
- Leave a configured guild and verify shared traffic stops. Test an unrelated guild is excluded.
- Test a gamepad login and switching between mouse/keyboard and gamepad; inspect `/gl bug`.
- Without a coordinator, verify no central privileges. With one configured, test the exact character
  on the correct realm and a same-named character outside that realm group.

Run `bash scripts/check.sh` for upstream checks, then build and run
`python scripts/test-guildlink.py dist/guildlink` for the profile's integration tests.

MIT license: retain LICENSE.txt and credit Olympus addon contributors. Upstream:
https://github.com/dnl-gentile/olympus-addon
Fork: https://github.com/bitspirit3/olympus-addon
