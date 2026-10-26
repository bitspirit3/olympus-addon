# GuildLink sister-guild build

This fork provides an independent GuildLink alpha for a small group of WoW Forever guilds.
See [the GuildLink guide](profiles/guildlink/README.md) for configuration, features and testing.

Build and test:

```sh
python scripts/build-guildlink.py --output dist/guildlink
python scripts/test-guildlink.py dist/guildlink
```

The installable archive contains `GuildLink` and `GuildLink_Arena`. Guild names are configured in
`profiles/guildlink/Settings.lua` before building, or in the installed `GuildLink/Settings.lua`.
They start empty until the actual names are decided. Use the same settings on every client.
The GitHub Actions **GuildLink build** workflow also produces a tested ZIP artifact.

The original Olympus source and README remain available for upstream fixes and reference.
Install the generated GuildLink folders for this fork. Retain the MIT license and contributor credits.
