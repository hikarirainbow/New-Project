# SCOPE
ARCH: 2D Metroidvania
CONTROLS:
- L/R: A/D
- Jump: Space
- Dash: C
- Attack: X
- Settings: ESC

STATUS:
- Walk/Jump/Gravity: DONE
- Variable Jump Height (Hollow Knight style, 128-220px, JUMP_MAX=-657, JUMP_CUT=-501): DONE
- Player Resize (64x128px, 2-tile collision 48x120): DONE
- Dash (0.2s, 0.18s iframe, 0.02s lerp, 0.8s CD): DONE
- Physics Layers: L1=Env, L2=Player, L3=Enemy, L4=Hitbox, L8=Item
- HP (100 HP max, HUD bar Tween): DONE
- Respawn (Fade 0.5s, restore +9999 HP, debuff max HP to 80): DONE
- Melee (X, 0.1s, 50x10 at 20px offset, blue visual): DONE
- Knockback (0.25s lock): DONE
- Dash Item (Green, Y=464, CD -> 0.4s): DONE
- Grab Enemy (PATROL/CHASE/DEAD states, raycast cliff/wall, 100px chase radius, wall-jump, CORPSE→Key pickup): DONE
- QTE Struggle (Space/E spam, success pushback, fail death): PLANNED
- Player Key Inventory (keys[], collect_key(), key_collected signal): DONE
- HUD Key Display (KeyLabel, shows collected keys): DONE
- Wall Slide/Jump: PLANNED
- Sandbox (Procedural 20x13 grid, 64x64 tiles brown/black, floor/ceiling/walls/3 platform rows): DONE
- Red Bean Static Enemy: DONE
- Patrol/Chase/Corpse Enemy: DONE
- Dash Upgrade Item: DONE
