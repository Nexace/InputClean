# Graph Report - TrackpadClean  (2026-10-28)

## Corpus Check
- Corpus is ~21,603 words - fits in a single context window. You may not need a graph.

## Summary
- 135 nodes · 205 edges · 12 communities (11 shown, 1 thin omitted)
- Source relations: 219 EXTRACTED · 1 INFERRED · 0 AMBIGUOUS (inferred confidence: 0.95).
- Token cost: unknown. Semantic subagents ran; their token counts are not exposed by the agent tooling.

## Community Hubs (Navigation)
- Profiling and Resource Tools
- Input Filtering and Startup
- Build and Product Behavior
- Application State and Types
- UI Stress Measurements
- Card Typography and Rendering
- Cleaning Mode Transitions
- Frosted Card Presentation
- Card Preview Design
- Menus and UI Checks
- Cleaning Mode Flags
- Card Dismissal and Cleanup

## God Nodes (most connected - your core abstractions)
1. `CleanApp` - 36 edges
2. `TrackpadClean` - 16 edges
3. `UIProfile` - 14 edges
4. `CardView` - 11 edges
5. `-stopCleaning` - 9 edges
6. `-startCleaning` - 9 edges
7. `-hideCard` - 7 edges
8. `-presentCardWithStatusdetailpinned` - 7 edges
9. `FilterInput` - 7 edges
10. `-showCardWithStatusdetailpinned` - 6 edges

## Surprising Connections (you probably didn't know these)
- `TrackpadClean` --references--> `Native app icon PNG renderer`  [EXTRACTED]
  README.md → tools/draw-icon.m
- `Teal rounded-square icon with white trackpad and sparkle` --conceptually_related_to--> `TrackpadClean`  [INFERRED]
  AppIcon.png → README.md
- `UI layout and cleanup check entry` --references--> `CleanApp`  [EXTRACTED]
  tests/ui-check.m → main.m
- `UIProfile` --inherits--> `CleanApp`  [EXTRACTED]
  tests/ui-profile.m → main.m
- `UI layout and cleanup check entry` --calls--> `-hideCard`  [EXTRACTED]
  tests/ui-check.m → main.m

## Import Cycles
- None detected.

## Communities (12 total, 1 thin omitted)

### Community 0 - "Profiling and Resource Tools"
Cohesion: 0.09
Nodes (11): Build and run live-session sampler, profile-live.sh script, profile.sh script, Live RAM and CPU session sampler, cleaning(), main(), Physical footprint, lifetime peak and one-core CPU samples, Event-tap cleaning mode detection (+3 more)

### Community 1 - "Input Filtering and Startup"
Cohesion: 0.12
Nodes (9): Logic check entry, -applicationDidFinishLaunching, CountEscape, FilterInput, IsMouseEvent, IsMouseSender, IsPointerEvent, ModeMask (+1 more)

### Community 2 - "Build and Product Behavior"
Cohesion: 0.11
Nodes (17): Teal rounded-square icon with white trackpad and sparkle, build.sh script, Application and login-command entry, Accessibility permission, Combined keyboard and trackpad cleaning, Trackpad cleaning mode, Keyboard cleaning mode, Opt-in aggregate input diagnostics (+9 more)

### Community 4 - "UI Stress Measurements"
Cohesion: 0.36
Nodes (8): UIProfile, -applicationDidFinishLaunching, -beginPhase, -cycleCard, -cycleMenu, -finish, -idleDone, -record

### Community 5 - "Card Typography and Rendering"
Cohesion: 0.25
Nodes (6): CardView, -accessibilityRole, -accessibilityValue, -drawRect, -updateLayer, -wantsUpdateLayer

### Community 6 - "Cleaning Mode Transitions"
Cohesion: 0.32
Nodes (7): -applicationWillTerminate, -clicked, -selectMode, -startCleaning, -stopCleaning, -toggleCleaning, ModeStatus

### Community 7 - "Frosted Card Presentation"
Cohesion: 0.29
Nodes (4): -mouseEntered, -presentCardWithStatusdetailpinned, -showCardWithStatusdetailpinned, -showHover

### Community 8 - "Card Preview Design"
Cohesion: 0.40
Nodes (5): Dark rounded card surface with fine light border, Divider above muted Click to pause and Esc ×5 to restore instructions, Teal dot beside Ready to clean status, TrackpadClean status card preview, Bold white TrackpadClean title

### Community 9 - "Menus and UI Checks"
Cohesion: 0.40
Nodes (3): -makeMenu, -presentMenu, UI layout and cleanup check entry

### Community 10 - "Cleaning Mode Flags"
Cohesion: 0.50
Nodes (4): CleanMode, CleanBoth, CleanKeyboard, CleanTrackpad

### Community 11 - "Card Dismissal and Cleanup"
Cohesion: 0.67
Nodes (3): -closeCard, -hideCard, -mouseExited

## Knowledge Gaps
- **19 isolated node(s):** `-wantsUpdateLayer`, `-accessibilityRole`, `-accessibilityValue`, `CleanTrackpad`, `CleanKeyboard` (+14 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 61 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `CleanApp` connect `Application State and Types` to `Input Filtering and Startup`, `Build and Product Behavior`, `UI Stress Measurements`, `Card Typography and Rendering`, `Cleaning Mode Transitions`, `Frosted Card Presentation`, `Menus and UI Checks`, `Cleaning Mode Flags`, `Card Dismissal and Cleanup`?**
  _High betweenness centrality (0.451) - this node is a cross-community bridge._
- **What connects `-wantsUpdateLayer`, `-accessibilityRole`, `-accessibilityValue` to the rest of the system?**
  _19 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Profiling and Resource Tools` be split into smaller, more focused modules?**
  _Cohesion score 0.09333333333333334 - nodes in this community are weakly interconnected._
- **Why does `TrackpadClean` connect `Build and Product Behavior` to `Profiling and Resource Tools`?**
  _High betweenness centrality (0.244) - this node is a cross-community bridge._
- **Should `Input Filtering and Startup` be split into smaller, more focused modules?**
  _Cohesion score 0.11857707509881422 - nodes in this community are weakly interconnected._
- **Why does `UIProfile` connect `UI Stress Measurements` to `Profiling and Resource Tools`, `Application State and Types`?**
  _High betweenness centrality (0.200) - this node is a cross-community bridge._
- **Should `Build and Product Behavior` be split into smaller, more focused modules?**
  _Cohesion score 0.11428571428571428 - nodes in this community are weakly interconnected._
## Coverage and integrity notes

- Corpus: 10 source/script files, README, app icon, and card preview. Mutable performance JSON and app bundles were excluded.
- Objective-C AST omissions were supplemented with verified C helper and entry-point nodes, including all three mode filters, test entries, icon renderer, and sampler.
- Raw extraction referenced 24 external imports/types before build; Graphify materialized their external nodes. The published graph has 0 dangling endpoints, 0 missing endpoints, 0 self-loops, and 0 exact duplicate edges.
- Graph health warning: 15 repeated endpoint relations share simple undirected pairs during clustering. All 220 original source relations and their call-site locations are preserved in graph.json, across 205 clustering pairs.
- Source paths in published outputs are repository-relative. Hidden interpreter/root metadata stays machine-local for incremental runs.
- Semantic token usage is unknown, not zero. The deterministic AST pass requires no model tokens.
- Validation scope: the ten-minute launched-app observation was idle-only; it does not measure cleaning-mode RAM or CPU. Trackpad blocking, native mouse sensitivity, and recovery were physically checked during development. Keyboard and combined modes pass automated callback checks, with physical confirmation still pending.
