# METROIDVANIA DESIGN GUIDELINES

## 1. Level Design & World Flow
- **Ability Gating**: Block paths using specialized barriers (gates) that require specific player abilities to bypass (e.g., high jump for tall ledges, dash for wide gaps).
- **Backtracking Loops**: Avoid dead ends. Design levels as interconnected loops. Standard paths should unlock shortcuts (one-way doors, breakable walls) connecting back to hubs.
- **Soft Locks**: Place high-progression rewards visible but unreachable early on to tease and guide the player's pathing.
- **Signposting**: Use unique landmarks, color-coded gates, or light sources to make zones memorable, helping players remember blocked paths later.

## 2. Player feel & Controls
- **Coyote Time**: Allow players to jump for a few frames (e.g., 5-8 frames) after leaving a platform edge.
- **Jump Buffering**: Register jump inputs pressed shortly (e.g., 5-10 frames) before hitting the ground, executing the jump immediately upon landing.
- **Invincibility Frames (iframes)**: Provide visual feedback (flashing sprite) and absolute damage immunity during recovery or specialized actions (like dashes).
- **Responsive Physics**: Use variable jump height (jump velocity scale on button release) and instant turnaround speed (high acceleration/friction) for precise platforming.

## 3. Camera Mechanics
- **Camera Lock Zones**: Use boundary limits to lock the camera inside rooms, preventing players from seeing outside the play area.
- **Smooth Damping**: Smooth camera movements (position smoothing) to reduce motion sickness, with a small focus window around the character.

## 4. Combat & Balance
- **Predictable Patterns**: Give enemies simple, readable movements so combat feels like a mechanical puzzle.
- **Damage Interruption**: Interrupt player attacks or movement states when taking damage to emphasize the threat.
