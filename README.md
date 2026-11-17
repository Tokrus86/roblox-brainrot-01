# Steal a Brainrot: Meme Meadows

A make.fun roblox-brainrot-01 entry: a 3D Roblox brainrot game built by a
coding agent in recorded sessions, published as a Public experience with its
own icon and thumbnail.

## The game

A brainrot parade walks the belt along the north edge of a green meadow.
Click a brainrot to buy it, keep it on your base, and watch the money tick
up every second. Twelve original characters climb a ladder of six rarities
(Common to Brainrot God), and any of them can be born Gold, Diamond or
Rainbow for up to 10x income.

The other half of the game is stealing: click a brainrot on somebody else's
base to snatch it, carry it home over your head, and set it down on your
own base. Slap a carrier (F, or the SLAP button) to make them drop it.
Lock your base for 30 seconds when the thieves circle. Rebirth to sell
everything and double your income forever. A tsunami sweeps the map every
two minutes — get back to your base or be washed home. Golden Hour doubles
everyone's income for a minute, every five minutes.

## Layout

- `main.ts` (Node 22, standard library only) hands the game in: it copies
  `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output` and
  writes `/output/dossier.json` with `vendor/makefun-roblox.ts`.
- `game.rbxl` is the place Rojo builds from `src/` and
  `default.project.json`; `screenshots/` holds three captures of it;
  `PLAY.json` names the published place once it is published.
- `src/shared/` holds the game's data: the brainrot cast (`BrainrotData`)
  and every tuning number (`Config`).
- `src/server/` holds the game itself, one module per job: `WorldBuilder`
  (the 3D meadow, belt and bases), `BrainrotFactory` (the models),
  `State` (the single source of truth for players), `Conveyor` (the
  parade), `Economy` (money, buying, rebirths, shop), `Steal` (stealing,
  carrying, slapping), `Events` (tsunami, Golden Hour) and `Net` (the
  RemoteEvents). `init.server.luau` wires them together.
- `src/client/` holds the HUD (`Hud`) and the cosmetic feedback
  (`Effects`): cash, income, your base's brainrots, Lock / Slap /
  Rebirth / Shop buttons, event banners and toasts.

## Build it

    ~/workspace/makefun/tools/rojo-7.7.1/rojo build default.project.json --output game.rbxl
    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

The rules are on the bounty's page (/bounty/roblox-brainrot-01) and in the
kit's RULES.txt, which gives every command in order (Before you submit,
then Enter). Publish the place from Roblox Studio first, set it Public,
put your make.fun play code in its description, fill in PLAY.json, and
upload its icon and thumbnail on the Creator Dashboard before you submit.
