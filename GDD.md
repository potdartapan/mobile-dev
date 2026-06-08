# Cheatventure
## Game Design Document — Demo Vertical Slice V0.1

| Field | Value |
|---|---|
| **Status** | First Playable — core loop functional |
| **Engine** | Godot 4.3 |
| **Platform** | Android + iOS Portrait |
| **Resolution** | 540 × 960 (dev); scales to device on export |
| **Art Direction** | Semi-3D Casual Idle Tycoon (Eatventure-style perspective) |

---

## 1. High Level Concept

Cheatventure is an idle restaurant tycoon game inspired by Eatventure, adapted to an Indian cuisine theme. The goal of this demo is **not differentiation yet** — it validates the core gameplay loop, economy pacing, upgrade systems, worker automation, delivery contracts, offline earnings, and the Indian asset pipeline.

The first demo contains a single Mumbai restaurant and mirrors Eatventure mechanics closely, with the addition of a delivery contract system.

---

## 2. Concept Statement

> Build an Indian restaurant empire by unlocking food stations, serving customers, hiring workers, accepting delivery contracts, and optimizing profits.

---

## 3. Genre

Idle Tycoon + Restaurant Simulation + Incremental Progression

---

## 4. Target Audience

- **Primary:** Casual mobile players, idle game fans, ages 13–40
- **Secondary:** Indian audiences familiar with regional cuisine; global players interested in Indian food themes
- **Session Target:** 2–8 minute active sessions with offline progression

---

## 5. Unique Selling Points

- Indian cuisine theme
- Multiple cuisine representation from across India
- Semi-3D Indian restaurant presentation
- Delivery contract system (bulk orders with upfront reward)
- Familiar idle gameplay with regional identity

---

## 6. Player Experience Goals

Desired emotions:

- Growth satisfaction
- Fast progression dopamine
- Optimization satisfaction
- Restaurant chaos and speed
- Feeling of building a successful Indian restaurant

---

## 7. Demo Scope

Single Mumbai restaurant — one complete playable level with full Eatventure-style mechanics plus delivery contracts. No city progression yet.

**Goal:** Validate mechanics before differentiation.

---

## 8. Food Stations

| # | Food Item | Cuisine | Cook Time | Base Reward | Upgrade Cost | Unlock Cost |
|---|---|---|---|---|---|---|
| 1 | Cutting Chai | West India | 2.0s | 5c | 30c | 0 (always unlocked) |
| 2 | Vada Pav | Mumbai | 2.5s | 10c | 60c | 150c |
| 3 | Pav Bhaji | Mumbai | 3.0s | 18c | 100c | 400c |
| 4 | Filter Coffee | South India | 3.0s | 18c | 100c | 800c |
| 5 | Momos | North/Himalayan | 3.5s | 30c | 160c | 2000c |
| 6 | Dosa | South India | 4.0s | 45c | 220c | 5000c |
| 7 | Chhole Bhature | North India | 5.0s | 70c | 300c | 12000c |
| 8 | Biryani | Hyderabad | 6.0s | 120c | 450c | 30000c |

**Upgrade scaling per level:**
- `coin_reward = base_coin_reward × (level + 1)`
- `production_time = max(0.5s, base_production_time − level × 0.15)`
- `upgrade_cost = base_upgrade_cost × 1.35^level`

**Panel upgrade multipliers (stack on top of level scaling):**
- Cook Speed purchases: `time_multiplier × 0.85` per purchase (up to 5×)
- 2× Profit purchase: `profit_multiplier × 2.0` (one-time)

---

## 9. Core Gameplay Loop

1. Customers enter restaurant and join shortest counter queue
2. Waiter takes order from front-of-queue customer (1 second interaction)
3. Cooking task added to chef's queue
4. Chef travels to station, cooks food (station's production_time)
5. Waiter picks up cooked food, delivers to customer at counter
6. Customer pays coins, leaves
7. Player spends coins on station upgrades, unlocks, and upgrade panel purchases
8. Automation increases — more workers, faster cooking, faster spawn rate
9. Loop repeats at increasing speed

### Progression Pacing Targets

| Phase | Upgrade Frequency |
|---|---|
| Early game | Every 15–30 seconds |
| Mid game | Every 30–60 seconds |
| Late game | Every 1–3 minutes |

---

## 10. Economy Philosophy

Prototype follows Eatventure pacing as a baseline. Goal is validating whether Indian theming preserves progression satisfaction. Economy will be tuned after first device playtest.

---

## 11. Restaurant Layout

Portrait 540×960. Three vertical zones:

```
y=0   ┌─────────────────────────┐
      │  HUD (CanvasLayer)       │
y=60  │  SpawnPoint (270, 60)   │  ← customers + delivery man enter
      │                          │
      │  DINING AREA  (beige)   │  ← customers queue, delivery man waits
      │  5 counter slots x=[54,162,270,378,486]
y=325 │  counter front line      │
y=340 ├══════ COUNTER ═══════════╡
y=400 ├─────────────────────────┤
      │  Waiter idle area        │
      │  KITCHEN  (tile gray)   │
      │  4×2 station grid        │
      │  Row 1 y=530, Row 2 y=710│
y=960 └─────────────────────────┘
```

---

## 12. Controls

Tap interactions only:
- Tap station Unlock button to unlock
- Tap station Upgrade button to upgrade
- Tap "Upgrades" button to open upgrade panel
- Tap "Delivery" button to open delivery panel
- Tap Accept on delivery offer to take bulk order

---

## 13. UI / HUD Structure

### Implemented
| Location | Element | Status |
|---|---|---|
| Top Left | Coin counter | ✅ Done |
| Bottom Left | Upgrades button → opens upgrade panel | ✅ Done |
| Bottom Right | Delivery button → opens delivery panel | ✅ Done |

### Planned (post-MVP or blocked)
| Location | Element | Blocker |
|---|---|---|
| Top Right | Gem counter + Add Gems | Gem system not designed |
| Below Coins | Active boost multiplier | Gem/boost system |
| Left | Popular dish boost | Boost system |
| Bottom | Fly button | Completion condition |
| Bottom | Ads Boost | AdMob integration |
| Bottom | Clothing | Assets needed |
| Right | Event button | Post-MVP |

### Vault System (planned)
Developer-tunable stats panel for balance testing:
- Walk speed, production speed, customer speed
- Profit multiplier, offline multiplier, demand boost

---

## 14. Worker System

### Waiter
- State machine: IDLE → GOING_TO_CUSTOMER → TAKING_ORDER (1s) → GOING_TO_PICKUP → DELIVERING → IDLE
- Priority 1: deliver ready food; Priority 2: take new orders
- Up to 5 waiters (1 base + 4 hired via upgrade panel)
- Speed upgradeable: +20% per purchase, up to 5×

### Chef
- State machine: IDLE → GOING_TO_STATION → COOKING → IDLE
- Owns the cooking timer — station is a passive location marker
- Carries food visual during cooking, passes it to the order dict on completion
- Up to 5 chefs (1 base + 4 hired via upgrade panel)
- Speed upgradeable: +20% per purchase, up to 5×

### Worker Pipeline (decoupled via GameState queues)
```
pending_orders  → waiter takes → adds to cooking_queue
cooking_queue   → chef takes → cooks → adds to ready_orders
ready_orders    → waiter picks up → delivers to customer or delivery man
```
All queues use pop_front() — safe for multiple workers.

---

## 15. Upgrade Panel System

Full-screen panel opened via "Upgrades" button. Persistent purchases saved to disk.

| Upgrade | Effect | Max | Base Cost | Cost Scale |
|---|---|---|---|---|
| Hire Waiter | +1 waiter NPC | 4 | 500c | ×3.0 |
| Hire Chef | +1 chef NPC | 4 | 800c | ×3.0 |
| Waiter Speed +20% | All waiters faster | 5 | 400c | ×2.0 |
| Chef Speed +20% | All chefs faster | 5 | 400c | ×2.0 |
| Advertise | -20% customer spawn time (min 1s) | 5 | 600c | ×2.5 |
| Cook Speed (per station) | -15% cook time for that station | 5 | station.base_upgrade_cost ×2 | ×2.0 |
| 2× Profit (per station) | Double coin reward for that station | 1 | station.base_coin_reward ×20 | — |

Cook speed and profit boosts only appear for unlocked stations.

---

## 16. Delivery System

Bulk contract orders that give the player an immediate coin reward in exchange for fulfilling a large order.

### Flow
1. Player taps "Delivery" button → panel shows 3 randomly generated offers
2. Each offer: a random unlocked station, quantity 5–15 items, reward = quantity × station.coin_reward × 1.5
3. Player accepts one → coins paid immediately → panel closes
4. A delivery man (blue NPC) enters from the left and waits in the dining area
5. N cooking tasks are injected into the shared cooking_queue (chef handles alongside regular orders)
6. As each item is cooked and delivered by waiter to delivery man, remaining count decrements
7. When all items received, delivery man walks off-screen and leaves
8. Only one active delivery at a time; new orders blocked until current is complete

### Design Intent
- Upfront reward creates an economy spike for the player
- Large orders clog the chef's queue, slowing regular customers — interesting tension
- Encourages upgrading cook speed and hiring more chefs

### Save / Resume
Active delivery is saved: `{station_name, remaining}`. On next launch, delivery man respawns and remaining cooking tasks are re-queued.

---

## 17. Offline Progression

### Decided approach (not yet implemented)
Local Unix timestamp with 8-hour cap. No backend required for MVP.

**Formula per unlocked station:**
```
coins_per_second = coin_reward / production_time
offline_coins    = coins_per_second × min(time_away, 28800) × 0.5
```
- `0.5` = 50% efficiency (chef bottleneck, no simulation)
- `28800` = 8 hours in seconds
- `last_save_timestamp` already stored in save file

**On return:** "While You Were Away" popup shows earnings + Claim button.

**Future path:**
- Pre-launch: NTP time check (validate device clock)
- Post-launch if successful: Firebase for server-authoritative time + cloud save
- Google Play Games / Apple Game Center: achievements and cross-device save only

---

## 18. Monetization

### Rewarded Ads (planned, post-MVP)
- No SDK integration in demo
- Natural ad slots: 2× coins for 30 min, speed boost for 5 min, instant offline claim
- Implementation: single `ads.gd` autoload; rest of game calls `Ads.show_rewarded(callback)`
- SDK: AdMob plugin for Godot (Android + iOS)

### No pay-to-win
- Ads are always optional, always rewarded
- No hard paywalls in the core loop

---

## 19. Technical Scope

| Field | Value |
|---|---|
| **Engine** | Godot 4.3 |
| **Language** | GDScript |
| **Platform** | Android + iOS Portrait |
| **Dev Resolution** | 540 × 960 |
| **Style** | Semi-3D placeholder art → Indian assets |
| **Save** | JSON to user:// (platform-appropriate path auto-managed by Godot) |
| **Goal** | Validate mechanics, not polish |

---

## 20. Success Criteria

- All mechanics functional
- Workers automate properly
- Delivery system creates satisfying economy spikes
- Offline earnings functional
- Upgrade pacing feels satisfying
- Indian assets feel natural when swapped in
- Player can reach all 8 stations
- All stations upgradeable to Level 150

---

## 21. Risks

| Risk | Mitigation |
|---|---|
| Derivative gameplay | Differentiate in later milestones (delivery system is first differentiator) |
| Asset workload | Placeholder assets functional; swap path is documented |
| Economy pacing | Tune after first device playtest |
| Chef bottleneck from delivery orders | Intentional tension; hire more chefs upgrade exists |

---

## 22. Development Roadmap

| Milestone | Description | Status |
|---|---|---|
| M1 | Vertical Slice — core loop, workers, upgrades, delivery, save/load | In progress |
| M2 | Polish + balancing — assets, animations, economy tuning, device testing | Not started |
| M3 | Monetization — AdMob rewarded ads | Not started |
| M4 | Differentiation — multiple cities, city perks, cuisine identity | Future |

---

## 23. Completion Condition

Restaurant is considered complete when:
- All 8 stations unlocked
- All 8 stations upgraded to Level 150
- Fly button unlocks

---

## 24. Future Systems *(Not Demo Scope)*

- Multiple cities
- City perks and progression
- Revisitable cities with passive systems
- City path choices
- Cuisine identity progression

---

## 25. Open Questions

- Final economy values (upgrade costs, station rewards, spawn timing)
- Vault stat ranges
- Gem system design (not started)
- Whether customer walk speed should be in the upgrade panel
