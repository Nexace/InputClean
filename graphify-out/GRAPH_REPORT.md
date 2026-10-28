# Graph Report - InputClean  (2026-10-28)

## Corpus Check
- 17 files · ~4,797 words
- Corpus fits in a single context window; the graph is retained as a source-navigation aid.
- Unclassified: 3 file(s) not represented in the graph (top: (none) 1, .icns 1, .plist 1)

## Summary
- 156 nodes · 234 edges · 15 communities (9 shown, 6 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: unknown; host inline semantic extraction used after the semantic worker was unavailable. Tooling does not expose host token counts.

## Community Hubs (Navigation)
- Card and Menu Interaction
- Cleaning State and Recovery
- Input Routing and Mode Filters
- CPU and Memory Sampling
- Product Behavior and Photos
- UI Resource Stress
- Card Rendering and Accessibility
- Mode Routing Regression
- Photo Backdrop Rendering
- Native App Build
- UI Profiling Entry
- Live Sampling Entry
- Logic Test Entry
- Application Entry

## God Nodes (most connected - your core abstractions)
1. `CleanApp` - 36 edges
2. `InputClean` - 18 edges
3. `PhotoApp` - 14 edges
4. `UIProfile` - 13 edges
5. `CardView` - 11 edges
6. `-startCleaning` - 9 edges
7. `-stopCleaning` - 8 edges
8. `-hideCard` - 8 edges
9. `-presentCardWithStatusdetailpinned` - 8 edges
10. `-cycleCard` - 7 edges

## Surprising Connections (you probably didn't know these)
- `Native menu with all three modes and combined default` --rendered_by--> `PhotoApp`  [EXTRACTED]
  assets/mode-menu.png → tools/screenshots.m
- `Combined paused card with five Esc recovery instruction` --rendered_by--> `PhotoApp`  [EXTRACTED]
  assets/paused.png → tools/screenshots.m
- `Clear ready card stating click pauses keyboard and trackpad` --rendered_by--> `PhotoApp`  [EXTRACTED]
  assets/ready.png → tools/screenshots.m
- `Screenshot regeneration` --references--> `PhotoApp`  [EXTRACTED]
  README.md → tools/screenshots.m
- `InputClean` --illustrates--> `Native menu with all three modes and combined default`  [EXTRACTED]
  README.md → assets/mode-menu.png

## Import Cycles
- None detected.

## Communities (15 total, 6 thin omitted)

### Community 0 - "Card and Menu Interaction"
Cohesion: 0.11
Nodes (9): CleanApp, -closeCard, -hideCard, -mouseEntered, -mouseExited, -presentCardWithStatusdetailpinned, -showCardWithStatusdetailpinned, -showHover (+1 more)

### Community 1 - "Cleaning State and Recovery"
Cohesion: 0.11
Nodes (15): -applicationDidFinishLaunching, -applicationWillTerminate, -clicked, -makeMenu, -presentMenu, -selectMode, -startCleaning, -stopCleaning (+7 more)

### Community 2 - "Input Routing and Mode Filters"
Cohesion: 0.11
Nodes (7): CountEscape, FilterInput, IsMouseEvent, IsMouseSender, IsPointerEvent, main, StatusIcon

### Community 3 - "CPU and Memory Sampling"
Cohesion: 0.12
Nodes (6): cleaning(), main(), now(), main, Stats, main

### Community 4 - "Product Behavior and Photos"
Cohesion: 0.16
Nodes (12): Keyboard, trackpad, cursor and cleaning sparkle icon, Native menu with all three modes and combined default, Combined paused card with five Esc recovery instruction, Clear ready card stating click pauses keyboard and trackpad, InputClean, PhotoApp, -applicationDidFinishLaunching, -capture (+4 more)

### Community 5 - "UI Resource Stress"
Cohesion: 0.36
Nodes (8): UIProfile, -applicationDidFinishLaunching, -beginPhase, -cycleCard, -cycleMenu, -finish, -idleDone, -record

### Community 6 - "Card Rendering and Accessibility"
Cohesion: 0.25
Nodes (6): CardView, -accessibilityRole, -accessibilityValue, -drawRect, -updateLayer, -wantsUpdateLayer

### Community 8 - "Mode Routing Regression"
Cohesion: 0.33
Nodes (3): main, ModeProbe, -startCleaning

### Community 9 - "Photo Backdrop Rendering"
Cohesion: 0.33
Nodes (3): main, PhotoBackdrop, -drawRect

## Knowledge Gaps
- **15 isolated node(s):** `-wantsUpdateLayer`, `-accessibilityRole`, `-accessibilityValue`, `CleanTrackpad`, `CleanKeyboard` (+10 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 75 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `CleanApp` connect `Card and Menu Interaction` to `Cleaning State and Recovery`, `Input Routing and Mode Filters`, `Product Behavior and Photos`, `UI Resource Stress`, `Card Rendering and Accessibility`, `Mode Routing Regression`?**
  _High betweenness centrality (0.419) - this node is a cross-community bridge._
- **What connects `-wantsUpdateLayer`, `-accessibilityRole`, `-accessibilityValue` to the rest of the system?**
  _15 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Card and Menu Interaction` be split into smaller, more focused modules?**
  _Cohesion score 0.10666666666666667 - nodes in this community are weakly interconnected._
- **Why does `UIProfile` connect `UI Resource Stress` to `Card and Menu Interaction`, `CPU and Memory Sampling`?**
  _High betweenness centrality (0.149) - this node is a cross-community bridge._
- **Should `Cleaning State and Recovery` be split into smaller, more focused modules?**
  _Cohesion score 0.10822510822510822 - nodes in this community are weakly interconnected._
- **Why does `PhotoApp` connect `Product Behavior and Photos` to `Card and Menu Interaction`, `Photo Backdrop Rendering`?**
  _High betweenness centrality (0.128) - this node is a cross-community bridge._
- **Should `Input Routing and Mode Filters` be split into smaller, more focused modules?**
  _Cohesion score 0.11428571428571428 - nodes in this community are weakly interconnected._
## Extraction audit

Fresh AST extraction plus host semantic documentation/image extraction. Free C function definitions are supplemented because the Objective-C extractor omits them. Raw measurement JSON is excluded as generated data. All source relations are preserved in graph.json; clustering and HTML use one connection per endpoint pair. Removed selected-mode persistence and the obsolete card-preview image are intentionally absent.

- 256 original relations; 234 clustering pairs.
- Missing endpoints: 0; dangling endpoints: 0; self-loops: 0.
- Same-endpoint relation instances: 22 (retained in JSON).
