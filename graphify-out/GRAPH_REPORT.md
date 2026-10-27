# Graph Report - InputClean  (2026-10-28)

## Corpus Check
- Corpus is ~20,819 words - fits in a single context window. You may not need a graph.

## Summary
- 147 nodes · 237 edges · 11 communities (10 shown, 1 thin omitted)
- Extraction source relations: 245 EXTRACTED · 10 INFERRED · 0 AMBIGUOUS (exact counts).
- Token cost: unknown. Semantic subagents ran; their token counts are not exposed by the agent tooling.

## Community Hubs (Navigation)
- Product Behavior and Preview
- Input Filtering and Startup
- Sampling and Icon Rendering
- Application State and Types
- UI Stress Measurements
- Card Presentation and Cleanup
- Mode Menu Regression
- Card Typography and Rendering
- Cleaning Mode Selection
- Application Icon Design
- Cleaning Mode Flags

## God Nodes (most connected - your core abstractions)
1. `CleanApp` - 38 edges
2. `InputClean` - 19 edges
3. `UIProfile` - 14 edges
4. `Menu mode regression, card layout and cleanup entry` - 12 edges
5. `CardView` - 11 edges
6. `-stopCleaning` - 10 edges
7. `-startCleaning` - 10 edges
8. `-hideCard` - 7 edges
9. `-presentCardWithStatusdetailpinned` - 7 edges
10. `FilterInput` - 7 edges

## Surprising Connections (you probably didn't know these)
- `Logic, menu regression and UI checks` --references--> `Menu mode regression, card layout and cleanup entry`  [INFERRED]
  README.md → tests/ui-check.m
- `InputClean` --references--> `Native keyboard, trackpad, cursor and sparkle PNG renderer`  [EXTRACTED]
  README.md → tools/draw-icon.m
- `-clicked` --references--> `Capture click type and Control modifier before UI dismissal`  [INFERRED]
  main.m → README.md
- `-startCleaning` --references--> `Deferred activation after menu tracking`  [INFERRED]
  tests/ui-check.m → README.md
- `-init` --references--> `Session-selected cleaning mode retention`  [INFERRED]
  main.m → README.md

## Import Cycles
- None detected.

## Communities (11 total, 1 thin omitted)

### Community 0 - "Product Behavior and Preview"
Cohesion: 0.09
Nodes (21): Dark rounded card surface with fine light border, Divider above muted Click to pause and Ctrl-click for options instructions, Teal dot beside Trackpad ready status, InputClean status card preview, Bold white InputClean title, build.sh script, InputClean application and login-command entry, Accessibility permission (+13 more)

### Community 1 - "Input Filtering and Startup"
Cohesion: 0.11
Nodes (11): Logic check entry, -applicationDidFinishLaunching, CountEscape, FilterInput, IsMouseEvent, IsMouseSender, IsPointerEvent, ModeMask (+3 more)

### Community 2 - "Sampling and Icon Rendering"
Cohesion: 0.09
Nodes (11): Build and run live-session sampler, profile-live.sh script, profile.sh script, Live RAM and CPU session sampler, cleaning(), main(), Physical footprint, lifetime peak and one-core CPU samples, Event-tap cleaning mode detection (+3 more)

### Community 4 - "UI Stress Measurements"
Cohesion: 0.36
Nodes (8): UIProfile, -applicationDidFinishLaunching, -beginPhase, -cycleCard, -cycleMenu, -finish, -idleDone, -record

### Community 5 - "Card Presentation and Cleanup"
Cohesion: 0.22
Nodes (7): -closeCard, -hideCard, -mouseEntered, -mouseExited, -presentCardWithStatusdetailpinned, -showCardWithStatusdetailpinned, -showHover

### Community 6 - "Mode Menu Regression"
Cohesion: 0.31
Nodes (5): -makeMenu, -presentMenu, Menu mode regression, card layout and cleanup entry, ModeProbe, -startCleaning

### Community 7 - "Card Typography and Rendering"
Cohesion: 0.25
Nodes (6): CardView, -accessibilityRole, -accessibilityValue, -drawRect, -updateLayer, -wantsUpdateLayer

### Community 8 - "Cleaning Mode Selection"
Cohesion: 0.31
Nodes (8): -applicationWillTerminate, -clicked, -init, -selectMode, -startCleaning, -stopCleaning, -toggleCleaning, Session-selected cleaning mode retention

### Community 9 - "Application Icon Design"
Cohesion: 0.40
Nodes (5): Dark pointer cursor with white outline at the lower right, White keyboard body with two rows of teal keys and a space bar, White four-point sparkle above the keyboard upper right corner, Pale inset trackpad with rounded teal outline, InputClean teal icon with keyboard, trackpad, cursor, and sparkle

### Community 10 - "Cleaning Mode Flags"
Cohesion: 0.50
Nodes (4): CleanMode, CleanBoth, CleanKeyboard, CleanTrackpad

## Knowledge Gaps
- **21 isolated node(s):** `-wantsUpdateLayer`, `-accessibilityRole`, `-accessibilityValue`, `CleanTrackpad`, `CleanKeyboard` (+16 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 63 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `CleanApp` connect `Application State and Types` to `Product Behavior and Preview`, `Input Filtering and Startup`, `UI Stress Measurements`, `Card Presentation and Cleanup`, `Mode Menu Regression`, `Card Typography and Rendering`, `Cleaning Mode Selection`, `Cleaning Mode Flags`?**
  _High betweenness centrality (0.466) - this node is a cross-community bridge._
- **What connects `-wantsUpdateLayer`, `-accessibilityRole`, `-accessibilityValue` to the rest of the system?**
  _21 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Product Behavior and Preview` be split into smaller, more focused modules?**
  _Cohesion score 0.08923076923076922 - nodes in this community are weakly interconnected._
- **Why does `InputClean` connect `Product Behavior and Preview` to `Cleaning Mode Selection`, `Sampling and Icon Rendering`, `Mode Menu Regression`?**
  _High betweenness centrality (0.295) - this node is a cross-community bridge._
- **Should `Input Filtering and Startup` be split into smaller, more focused modules?**
  _Cohesion score 0.11 - nodes in this community are weakly interconnected._
- **Why does `UIProfile` connect `UI Stress Measurements` to `Sampling and Icon Rendering`, `Application State and Types`?**
  _High betweenness centrality (0.172) - this node is a cross-community bridge._
- **Should `Sampling and Icon Rendering` be split into smaller, more focused modules?**
  _Cohesion score 0.09333333333333334 - nodes in this community are weakly interconnected._
## Coverage and integrity notes

- Corpus: 10 source/script files, README, app icon, and card preview. Mutable performance JSON and app bundles were excluded.
- Objective-C AST omissions were supplemented with verified C helper and entry-point nodes, including all three mode filters, test entries, icon renderer, and sampler.
- Raw extraction referenced 25 external imports/types before build; Graphify materialized their external nodes. The published graph has 0 dangling endpoints, 0 missing endpoints, 0 self-loops, and 0 exact duplicate edges.
- Graph health warning: 18 repeated endpoint relations share simple undirected pairs during clustering. All 255 original source relations and their call-site locations are preserved in graph.json, across 237 clustering pairs.
- Source paths in published outputs are repository-relative. Hidden interpreter/root metadata stays machine-local for incremental runs.
- Semantic token usage is unknown, not zero. The deterministic AST pass requires no model tokens.
- Validation scope: the earlier ten-minute live baseline was idle-only. Physical keyboard blocking and five-Esc recovery, trackpad blocking, and native mouse behavior are documented as checked. Final Control-click menu and combined-mode physical confirmation remain pending. ModeProbe regression coverage asserts activation is deferred until tracking closes and the chosen mode survives stop/toggle; ModeMenuClick checks right-click and Control-click classification.
