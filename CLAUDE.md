# Cheatventure — Claude Code Reference

## Project Overview
Mobile idle restaurant tycoon game inspired by Eatventure, themed around Indian cuisine.
Engine: Godot 4.3 | Language: GDScript | Target: Android + iOS | Dev platform: Linux

## User Profile
- Basic Python knowledge, minimal game dev experience
- Wants to learn Godot while Claude writes the code
- Claude writes all code; user does editor work (attaching scripts, configuring nodes)
- Prefers concise explanations with clear "what to do in the editor" instructions

---

## Project Structure
```
cheatventure/                        ← project root
├── CLAUDE.md                        ← this file
├── GDD.md                           ← full game design document
├── tasks.md                         ← development task tracker
├── .mcp.json                        ← Godot MCP server config
└── cheatventure/                    ← Godot project folder
    ├── project.godot
    ├── scenes/
    │   ├── game.tscn                ← main scene (set as default in project settings)
    │   ├── station.tscn             ← reusable food station
    │   ├── customer.tscn            ← customer scene
    │   ├── waiter.tscn              ← waiter NPC scene
    │   └── chef.tscn                ← chef NPC scene
    │   (no delivery_man.tscn — delivery man built entirely in code)
    ├── scripts/
    │   ├── game_state.gd            ← Autoload singleton (MUST be registered)
    │   ├── game.gd                  ← main scene controller
    │   ├── customer.gd
    │   ├── waiter.gd
    │   ├── chef.gd
    │   ├── food_station.gd
    │   ├── food_item.gd             ← static factory for food visuals
    │   ├── hud.gd
    │   ├── upgrade_panel.gd         ← full-screen upgrade panel (CanvasLayer)
    │   ├── delivery_panel.gd        ← full-screen delivery panel (CanvasLayer)
    │   └── delivery_man.gd          ← delivery man NPC (no scene file, built in code)
    └── assets/
        ├── characters/              ← drop character PNGs here when ready
        └── food/                    ← drop food item PNGs here when ready
```

---

## Critical Godot Setup (must be correct for game to run)

### Autoload
`game_state.gd` must be registered as Autoload with the name **GameState**:
- Project Settings → Globals → Autoload tab
- Path: `res://scripts/game_state.gd`, Name: `GameState`

### Viewport
- Width: 540, Height: 960
- Project Settings → Display → Window

### Main Scene
- `res://scenes/game.tscn`

### game.tscn node structure
The root Game node must have these children (user adds in editor):
- `DiningArea` (ColorRect)
- `Counter` (ColorRect)
- `KitchenArea` (ColorRect)
- `Stations` (Node2D) — stations spawned here in code
- `Characters` (Node2D) — waiter, chef, delivery man spawned here
- `Customers` (Node2D) — customers spawned here
- `SpawnPoint` (Marker2D, position 270,60)
- `SpawnTimer` (Timer, wait_time=4.0, autostart=true)
- `HUD` (CanvasLayer, script: hud.gd) with child `CoinLabel` (Label)
- `UpgradePanel` (CanvasLayer, layer=10, script: upgrade_panel.gd)
- `DeliveryPanel` (CanvasLayer, layer=10, script: delivery_panel.gd)

### MCP Server (for Claude Code tooling)
`.mcp.json` at project root:
```json
{
  "mcpServers": {
    "godot": {
      "command": "npx",
      "args": ["-y", "@coding-solo/godot-mcp"],
      "env": { "GODOT_PATH": "/usr/local/bin/godot" }
    }
  }
}
```
Also requires `.claude/settings.json` with `"enableAllProjectMcpServers": true`.

---

## Layout & Coordinate System

Portrait 540×960. Y increases downward (Godot standard).

```
y=0   ┌─────────────────────────┐
      │  HUD (CanvasLayer)       │
y=60  │  SpawnPoint (270, 60)   │  ← customers enter here
      │                          │
      │  DINING AREA  (beige)   │  ← customers queue at counter
      │  DeliveryMan waits at (20, 280) — left side
      │  5 counter slots         │
y=325 │  counter front line      │
y=340 ├══════ COUNTER ═══════════╡  ← brown bar (y 340–400)
y=400 ├─────────────────────────┤
      │  Waiter idle positions  │  ← y=450, multiple spread across x
      │  KITCHEN  (tile gray)   │
      │  ┌────┐ ┌────┐ ┌────┐  │  ← station row 1 (y=530)
      │  └────┘ └────┘ └────┘  │
      │  ┌────┐ ┌────┐ ┌────┐  │  ← station row 2 (y=710)
      │  └────┘ └────┘ └────┘  │
      │  Chef idle positions    │  ← y=630, multiple spread across x
y=960 └─────────────────────────┘
```

### Counter slot X positions (5 slots)
`[54, 162, 270, 378, 486]` at y=325

### Station grid positions
Row 1 (y=530): x = `[75, 205, 335, 465]`
Row 2 (y=710): x = `[75, 205, 335, 465]`
Station size: 110×90px

### Worker spawn positions (defined in game.gd)
```gdscript
WAITER_SPAWN_POSITIONS = [(270,450), (180,450), (360,450), (130,450), (410,450)]
CHEF_SPAWN_POSITIONS   = [(270,630), (160,630), (380,630), (100,630), (440,630)]
```

### Delivery man position
- Waiting spot: `Vector2(20, 280)` — left side of dining area
- Enters/exits from: `Vector2(-100, 280)` — off left edge

---

## Architecture Overview

### Order pipeline (regular customers)
```
Customer spawns at top
  → joins shortest counter slot (GameState.join_counter)
  → walks to queue position
  → reaches front → picks random unlocked station
  → GameState.add_pending_order

Waiter (IDLE)
  → Priority 1: take_ready_order → GOING_TO_PICKUP → DELIVERING
  → Priority 2: take_pending_order → GOING_TO_CUSTOMER → TAKING_ORDER (1s)
  → adds cooking task → IDLE

Chef (IDLE)
  → take_cooking_task → GOING_TO_STATION → COOKING (production_time countdown)
  → creates FoodItem visual on arrival, carries during cooking
  → finish: detach food visual, mark_order_ready → IDLE

Waiter (GOING_TO_PICKUP)
  → arrives at station → reparents food visual to self
  → DELIVERING → arrives at customer → customer.receive_food(coin_reward)
  → food visual freed → IDLE

Customer
  → receives food → coins_earned signal → GameState.add_coins
  → GameState.leave_counter → walks to y=-120 → queue_free
```

### Delivery pipeline
```
Player accepts delivery offer
  → GameState.active_delivery = {station_name, remaining}
  → GameState.add_coins(reward)  ← coins paid immediately
  → DeliveryMan spawns, walks to Vector2(20, 280)
  → N cooking tasks injected into GameState.cooking_queue

Chef handles delivery tasks same as regular orders
  → Waiter picks up, delivers to delivery_man.position
  → delivery_man.receive_food() → remaining -= 1
  → When remaining == 0: delivery_man walks off-screen, queue_free
  → GameState.active_delivery = {}
```

### GameState queues and state
```gdscript
coins:            int
upgrade_counts:   Dictionary  # {upgrade_id: int} — all panel purchases
active_delivery:  Dictionary  # {station_name, remaining} or {}
pending_orders:   Array       # customers waiting for waiter to take order
cooking_queue:    Array       # {customer, station} — shared by regular + delivery
ready_orders:     Array       # {customer, station, food_visual}
counter_queues:   Array       # 5 arrays, one per slot, each holds Customer refs
```

### Key data flow rules
- `pop_front()` on all queues — safe for multiple workers
- `is_instance_valid()` before every cross-node call that could be freed
- Food visual reparented chef → order dict → waiter, freed on delivery
- Stations are purely passive — no queue, no timer
- Chef owns the cooking timer
- Delivery man implements `receive_food()` same interface as Customer — waiter code unchanged
- Delivery man has NO scene file; built entirely in `_ready()` via code

---

## FoodStation properties

```gdscript
# Base data (set from game.gd STATION_DATA at build time)
station_name, base_production_time, base_coin_reward, base_upgrade_cost, unlock_cost

# Runtime state
level: int
is_unlocked: bool
profit_multiplier: float  # default 1.0, set by upgrade panel (2× profit purchase)
time_multiplier: float    # default 1.0, set by upgrade panel (cook speed purchase)

# Computed (call refresh_stats() to recalculate)
coin_reward = int(base_coin_reward * (level + 1) * profit_multiplier)
production_time = max(0.5, (base_production_time - level * 0.15) * time_multiplier)
```

`refresh_stats()` must be called after any change to level, profit_multiplier, or time_multiplier.

---

## Station Data (defined in game.gd)

| # | Name | Cook time | Reward | Upgrade cost | Unlock cost |
|---|---|---|---|---|---|
| 0 | Cutting Chai | 2.0s | 5c | 30c | 0 (always unlocked) |
| 1 | Vada Pav | 2.5s | 10c | 60c | 150c |
| 2 | Pav Bhaji | 3.0s | 18c | 100c | 400c |
| 3 | Filter Coffee | 3.0s | 18c | 100c | 800c |
| 4 | Momos | 3.5s | 30c | 160c | 2000c |
| 5 | Dosa | 4.0s | 45c | 220c | 5000c |
| 6 | Chhole Bhature | 5.0s | 70c | 300c | 12000c |
| 7 | Biryani | 6.0s | 120c | 450c | 30000c |

---

## Upgrade Panel

Opened via "Upgrades" button (bottom left HUD). Built entirely in code by `upgrade_panel.gd`.

| id | Effect | max_count | base_cost | cost_scale |
|---|---|---|---|---|
| hire_waiter | Spawn extra waiter | 4 | 500 | ×3.0 |
| hire_chef | Spawn extra chef | 4 | 800 | ×3.0 |
| waiter_speed | All waiters: _speed ×1.2 | 5 | 400 | ×2.0 |
| chef_speed | All chefs: _speed ×1.2 | 5 | 400 | ×2.0 |
| advertise | SpawnTimer.wait_time ×0.8 (min 1s) | 5 | 600 | ×2.5 |
| cook_speed_{name} | station.time_multiplier ×0.85 | 5 | base_upgrade_cost×2 | ×2.0 |
| double_profit_{name} | station.profit_multiplier ×2.0 | 1 | base_coin_reward×20 | — |

All purchases stored in `GameState.upgrade_counts`. On load, `game.gd._apply_save()` restores:
- Station multipliers applied then `station.refresh_stats()` called
- Worker speed: applied in each worker's `_ready()` via `pow(1.2, upgrade_counts.get(...))`
- Extra workers: spawned in `game.gd._ready()` after `_apply_save()`
- Spawn timer: adjusted in `game.gd._ready()` after `_apply_save()`

---

## Save / Load System

**Save file:** `user://save.json`
- Linux dev: `~/.local/share/godot/app_userdata/cheatventure/save.json`
- Android: private app storage
- iOS: app Documents folder

**Save triggers:**
1. Every upgrade/unlock/delivery accept
2. Every 60 seconds (auto-save in `_process`)
3. App backgrounded (`NOTIFICATION_APPLICATION_PAUSED`)
4. Each delivery item received (updates remaining count)

**Save format:**
```json
{
  "coins": 1500,
  "upgrades": {"hire_waiter": 1, "waiter_speed": 2, "cook_speed_Cutting Chai": 3},
  "active_delivery": {"station_name": "Pav Bhaji", "remaining": 7},
  "stations": [
    {"name": "Cutting Chai", "level": 3, "unlocked": true},
    {"name": "Vada Pav",     "level": 0, "unlocked": false}
  ],
  "last_save_timestamp": 1717891200
}
```

**Load sequence (game.gd._ready):**
1. `_build_stations()` — instantiate all 8 with defaults
2. `_apply_save()`:
   - Restore coins, upgrade_counts, active_delivery
   - Call `station.apply_save_data()` for each station (restores level + unlock)
   - Apply station multipliers from upgrade_counts, call `refresh_stats()`
3. Spawn base waiter + chef (they read speed upgrade_counts in their `_ready()`)
4. Spawn hired workers (loop over upgrade_counts["hire_waiter"] / ["hire_chef"])
5. Apply advertise upgrade to SpawnTimer
6. Connect UpgradePanel + DeliveryPanel signals
7. `_restore_delivery()` — if active_delivery exists, spawn delivery man + re-queue tasks

**Reset save (dev only):**
```bash
rm ~/.local/share/godot/app_userdata/cheatventure/save.json
```

---

## Offline Progress (decided, not yet implemented)

**Decision:** Local Unix timestamp with 8-hour cap.

**Formula per unlocked station:**
```
coins_per_second = coin_reward / production_time
offline_coins    = coins_per_second × min(time_away, 28800) × 0.5
```

**`last_save_timestamp` already saved.** Still needed:
- Calculation function in `game_state.gd` or `game.gd`
- "While you were away" popup CanvasLayer with Label + Claim button

---

## Asset Replacement Plan (when assets are ready)

**Food items** — `food_item.gd` `create_for_station()`:
- Replace `Polygon2D` block with `Sprite2D` loading `res://assets/food/[name].png`
- Recommended: 64×64px PNG, transparent background

**Characters** — swap in editor:
- `customer.tscn`: ColorRect → Sprite2D (`assets/characters/customer.png`)
- `waiter.tscn`: WaiterRect → Sprite2D (`assets/characters/waiter.png`)
- `chef.tscn`: ChefBody + ChefHat → single Sprite2D (`assets/characters/chef.png`)
- `delivery_man.gd` `_ready()`: replace ColorRect creation with Sprite2D
- Recommended: 64×96px PNG, transparent background

No script logic changes needed for character swaps.

**Upgrade panel icons** — add to each row in `upgrade_panel.gd`:
- 48×48px PNGs in `assets/ui/` — one per upgrade type

---

## What to Build Next (priority order)

1. **Android export** — device test reveals real touch/layout issues
2. **Offline progress** — decided formula + welcome-back popup
3. **Completion condition** — detect all 8 stations at Level 150, unlock Fly button
4. **Economy tuning** — after first device playtest
5. **Customer walk speed upgrade** — add to upgrade panel (minor)

---

## Coding Conventions

- No comments unless the WHY is non-obvious
- No defensive error handling for scenarios that can't happen
- Use `is_instance_valid()` for any cross-node reference that could be freed
- State machines use `enum State` + `match _state`
- All queues use `pop_front()` for FIFO — supports multiple workers safely
- `GameState.save()` called after every player-triggered state change
- Stations always instantiated in code (`game.gd._build_stations`), never placed manually in editor
- Panels (upgrade, delivery) build all UI nodes in code — no scene files for panels
- Delivery man built entirely in code — no scene file
