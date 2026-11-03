# Krusty Krab Tycoon

A Roblox burger tycoon with an underwater neighborhood, four restaurant plots, a yellow sponge-inspired costume, and a hands-on cooking loop. Earn cash by grilling and serving burgers, then grow your restaurant with seven upgrades.

## Open the game in Roblox Studio

1. Download [KrustyKrabTycoon.rbxlx](KrustyKrabTycoon.rbxlx) from the repository root. On GitHub, open the file and use **Download raw file**. You can also build it from source using the commands below.
2. Open Roblox Studio on Windows or macOS and choose **File → Open from File**, then select the place file.
3. Press **Play** to start a solo session. A restaurant is assigned automatically and your character is moved to its plot. Follow the on-screen instructions to cook your first burger.

No paid assets, external services, or secrets are required. The place includes a visible map in Studio's editor. When you press Play, the server rebuilds it from the same source and connects the gameplay interactions.

Use the nearby interaction prompts: **hold E** on keyboard, tap on touch devices, or use the displayed controller button. The **How to play** button, or **H**, reopens the instructions. The upgrade list in the HUD shows your progress; purchases happen at the upgrade pads in your restaurant.

## Play

- Start cooking at your grill. The first side takes **3 seconds**.
- Flip the burger and wait **2 seconds**, then pick it up and serve it for **$25**.
- Purchase the second grill for **$120**, then progress through quick-flip cooking, secret sauce, dining tables, a neon sign, a jellyfish garden, and the golden spatula. The final upgrade costs **$1,100**.
- Fully upgraded burgers earn **$69**. Quick-flip cooking reduces both cooking stages to 65% of their original duration.
- Explore beyond your restaurant and collect **$10** coins, which return after **30 seconds**.
- Up to **four players** can own separate restaurant plots in one server. Set the published experience's maximum player count to four; extra players can explore while waiting for a plot to become free.

The starting balance is **$50**. Gameplay cash is earned in the game; there are no Robux purchases.

## Build and develop

The source uses **Rojo 7.7.1** to build/sync the place and **Lune 0.11.1** to run the pure economy tests. Roblox Studio itself is required to play or test the 3D game.

For a fresh Linux x86-64 checkout, install the pinned tools with Python 3. The installer verifies the official release ZIP checksums:

```sh
python3 scripts/install-tools.py
export PATH="$PWD/.tools:$PATH"
```

On Windows or macOS, install the matching platform versions from the official [Rojo 7.7.1 release](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.1) and [Lune 0.11.1 release](https://github.com/lune-org/lune/releases/tag/v0.11.1), and add them to your command path. The checked-in installer is for Linux x86-64 only.

In this prepared cloud environment, the tools are available in `/workspace/.tools`:

```sh
cd /workspace/SQL-Interface
export PATH="/workspace/.tools:$PATH"
lune run scripts/check.luau
lune run scripts/build.luau
lune run tests/economy.luau
lune run tests/profile_store.luau
lune run tests/gameplay.luau
```

The build script runs Rojo, bakes the map for editing, and produces `build/KrustyKrabTycoon.rbxlx` and `build/KrustyKrabTycoon.rbxl`. It also refreshes the downloadable `KrustyKrabTycoon.rbxlx` at the repository root and checks that the scripts, four restaurant plots, and map survive serialization. After changing source, rebuild before opening the generated place. For setup or validation that should leave tracked files unchanged, use `lune run scripts/build.luau --no-snapshot`.

To edit with a live Studio session, install the matching official Rojo Studio plugin, open the generated place, and run:

```sh
rojo serve default.project.json --address 127.0.0.1 --port 34872
```

Run this on the same desktop as Studio. Use the Rojo plugin's **Connect** button with host `127.0.0.1` and port `34872`. Sync changes before starting a new play session. A Rojo server syncs source into Studio; it does not host a playable Roblox game.

Use the existing checkout for cloud tasks; a Git worktree is unnecessary. The `build/` directory and downloaded tools are ignored by Git; the root place file is tracked for direct download.

## Change balance and saving

`src/shared/Config.luau` contains the title, starting cash, cooking times, collectible rewards, upgrade prices, and persistence setting. Shared economy rules live in `src/shared/Economy.luau`.

Server gameplay starts in `src/server/Game.server.luau`; the runtime map, profile storage, and costume have separate modules in the same directory. The client HUD lives in `src/client/Interface.client.luau`. The yellow sponge costume is applied automatically when the character spawns.

**Saving is off by default.** Each server session starts fresh, so players can try the game without publishing it or configuring DataStores. To enable persistent profiles:

1. Publish the place to Roblox.
2. Set `Config.PersistenceEnabled = true` in `src/shared/Config.luau` and rebuild or sync the place.
3. For Studio testing, enable **Game Settings → Security → Enable Studio Access to API Services**.
4. Test leaving and rejoining with a test account before relying on saved progress.

The DataStore name is configurable in the same file. No API key or other secret is needed.

## Validation

`lune run scripts/check.luau` compiles the Luau source without running Roblox services. The standalone economy suite covers sale payouts, upgrade progression, rejected purchases, cooking multipliers, and sanitization of saved profiles. The profile-store suite tests persistence disabled mode, session leases, failed loads, and saves with mocked DataStores. The gameplay suite exercises the server's cooking, serving, ownership, and plot lifecycle using simulated Roblox services. These checks run outside Studio and make no live DataStore calls.

Roblox Studio is installed on your desktop, but it does not run in this Linux cloud environment. The game has **not been playtested in-engine here**. Before publishing, check these behaviors in your desktop Studio:

- Join and verify automatic restaurant assignment, finish the start → flip → pickup → serve loop, and verify the cash increase.
- Buy upgrades in order; check their prices, restaurant changes, extra grill, faster cooking, and final $69 payout.
- Touch coins and wait for their cooldown; verify the sponge costume appears again after respawning.
- Use Studio's multiplayer test with four players and verify players cannot use another owner's restaurant or spend their cash.
- Leave and rejoin to verify the intended session-only behavior, or test DataStore saving separately after enabling it.
