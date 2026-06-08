# Cheatventure — Development Task Tracker
## Milestone 1: Vertical Slice (Demo V0.1)

---

### Phase 1 — Project Foundation
- [x] Godot 4.3 project created
- [x] Portrait viewport configured (540 × 960)
- [x] Folder structure set up (`scenes/`, `scripts/`)
- [x] Godot MCP server connected to Claude Code

---

### Phase 2 — Core Scene & Restaurant Layout
- [x] Restaurant background (dark brown ColorRect)
- [x] Semi-3D portrait layout
- [x] Customer entrance at top, station in lower half
- [x] SpawnPoint and SpawnTimer configured
- [x] Three-zone layout: Dining (top), Counter (middle bar), Kitchen (bottom)
- [x] 5-slot counter queue system (customers form independent lines)

---

### Phase 3 — Customer System
- [x] Customer spawning (timed, from top of screen)
- [x] Customer walking toward station
- [x] Customer exits after being served
- [x] Customers queue at counter (5 independent lanes, max 4 deep each)
- [x] Customer exits upward after receiving food from waiter

---

### Phase 4 — Station & Economy Core
- [x] Food station (Cutting Chai) with production timer
- [x] Coin reward on customer served
- [x] Coin counter HUD (top left)
- [x] GameState singleton (global coin management)
- [x] Station upgrade button (tap to upgrade)
- [x] Upgrade cost scaling per level (exponential)
- [x] Coin reward scaling per level
- [x] Production speed scaling per level
- [x] Level display on station

---

### Phase 5 — All 8 Food Stations
- [x] Station data resource (name, cost, reward, speed per station)
- [x] All 8 stations in 4×2 grid in kitchen area
- [x] Station unlock flow (locked → gray, tap "Unlock N c" button)
- [x] Chai starts unlocked; others unlock with coins
- [ ] Restaurant layout expands as stations unlock (cosmetic — currently all visible, post-MVP)

---

### Phase 6 — Worker System
- [x] Waiter NPC: takes orders from counter, fetches food from kitchen, delivers to customer
- [x] Chef NPC: functional cooking engine — moves to ordered station, cooks, passes food to waiter
- [x] Decoupled waiter/chef pipeline via GameState queues (pending_orders, cooking_queue, ready_orders)
- [x] Food item visuals (Polygon2D shapes) carried by chef while cooking, then by waiter to customer
- [x] Hire additional waiters (up to 4 extra, via upgrade panel)
- [x] Hire additional chefs (up to 4 extra, via upgrade panel)
- [x] Worker speed upgrade (waiter +20% / chef +20%, up to 5×, via upgrade panel)
- [ ] Customer patience timer — decided to skip, Eatventure doesn't have this

---

### Phase 7 — Upgrade Panel System
- [x] Upgrade panel UI (full-screen overlay, opened via "Upgrades" button at bottom)
- [x] Hire Waiter upgrade (up to 4, cost ×3 each: 500 → 1500 → 4500 → 13500)
- [x] Hire Chef upgrade (up to 4, cost ×3 each: 800 → 2400 → 7200 → 21600)
- [x] Waiter Speed +20% (up to 5×, cost ×2 each starting 400c)
- [x] Chef Speed +20% (up to 5×, cost ×2 each starting 400c)
- [x] Advertise: -20% customer spawn time (up to 5×, min 1s, cost ×2.5 each starting 600c)
- [x] Cook Speed -15% per station (up to 5× per station, cost ×2 each)
- [x] 2× Profit per station (one-time per station)
- [x] All upgrades persist via save/load (stored in GameState.upgrade_counts)
- [ ] Customer walk speed upgrade
- [ ] Upgrade icons / card art (wait for assets)

---

### Phase 8 — Full HUD
- [x] Coin counter (top left)
- [x] Upgrades button (bottom left — opens upgrade panel)
- [x] Delivery button (bottom right — opens delivery panel)
- [ ] Fly button (bottom) — unlocks when completion condition met (Phase 11)
- [ ] Ads Boost button — 2× coins for 30 min; blocked on AdMob integration (decided: post-MVP)
- [ ] Gem counter (top right) — blocked on gem system (not designed yet)
- [ ] Active boost multiplier display — blocked on gem/boost system
- [ ] Popular dish boost button — blocked on boost system
- [ ] Clothing button — wait for assets
- [ ] Helper system button — post-MVP
- [ ] Event button — post-MVP

---

### Phase 9 — Delivery System
- [x] Delivery panel UI (full-screen overlay, 3 randomly generated bulk orders)
- [x] Orders show station name, quantity (5–15 items), coin reward (1.5× rate)
- [x] Coins paid immediately on accept
- [x] Delivery man NPC spawns and walks to waiting position (left side of dining area)
- [x] Cooking tasks injected directly into shared cooking_queue
- [x] Delivery man counts down remaining items, leaves when all received
- [x] One delivery at a time (panel shows active status if delivery running)
- [x] Save and resume — active delivery persists across app restarts
- [x] GameState.active_delivery tracks {station_name, remaining} for save/load

---

### Phase 10 — Vault System (GDD §13)
- [ ] Vault panel UI
- [ ] Editable dev stats: walk speed, production speed, customer speed
- [ ] Profit multiplier tuning
- [ ] Offline multiplier tuning
- [ ] Demand boost tuning

---

### Phase 11 — Offline Progression
- [x] Save game state to disk (JSON via FileAccess to user://)
- [x] Load game state on launch (coins, station levels/unlocks, upgrades, active delivery)
- [x] Auto-save every 60s + on app pause + on every upgrade/unlock/delivery
- [x] last_save_timestamp stored for offline calculation
- [ ] Calculate coins earned while offline (local timestamp + 8hr cap, 50% efficiency)
- [ ] "While You Were Away" popup with claim button

---

### Phase 12 — Completion Condition
- [ ] Detect when all 8 stations are unlocked and at Level 150
- [ ] Fly button unlocks when completion condition met

---

### Phase 13 — Android Export & Device Testing
- [ ] Install JDK 17 (`sudo apt install openjdk-17-jdk`)
- [ ] Install Android SDK (via Android Studio)
- [ ] Create debug keystore
- [ ] Configure Android export preset in Godot (package name, keystore, architectures)
- [ ] Download Godot 4.3 export templates
- [ ] Export APK and test on device
- [ ] Fix any touch target or layout issues found on device

---

## Milestone 2: Polish + Balancing
- [ ] Economy tuning (pacing: upgrade every 15–30s early, 1–3 min late)
- [ ] Indian asset replacement (sprites, backgrounds, food icons, upgrade icons, delivery man)
- [ ] Coin pop animation (+Nc floating text on customer pay) — do after assets
- [ ] Cooking progress bar on active station — do after assets
- [ ] "Afford" highlight on station buttons — do after assets
- [ ] Sound effects and music
- [ ] Screen transitions and animations

---

## Milestone 3: Monetization
- [ ] AdMob integration (Android + iOS)
- [ ] Rewarded ads: 2× coins for 30 min, speed boost, instant offline claim
- [ ] Ads Boost button in HUD

---

## Milestone 4: Differentiation Systems *(Future)*
- [ ] Multiple cities
- [ ] City perks
- [ ] Revisitable cities
- [ ] Passive city systems
- [ ] City path choices
- [ ] Cuisine identity progression

---

## Open Questions
- Exact economy tuning values (upgrade costs, station rewards, spawn rate)
- Vault stat ranges
- Gem system design (not started)
- Whether to add customer walk speed upgrade to panel
