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
- Variable Jump Height (Hold Space to jump higher, on release velocity.y *= 0.1, JUMP_VELOCITY=-450, min jump ~5px): DONE
- Player Resize (32x64px, collision 32x64): DONE
- Camera Zoom (Vector2(1.5, 1.5)): DONE
- Dash (0.2s, 0.18s iframe, 0.02s lerp, 0.8s CD): DONE
- Physics Layers: L1=Env, L2=Player, L3=Enemy, L4=Hitbox, L8=Item
- HP (100 HP max, HUD bar Tween): DONE
- Respawn (Fade 0.5s, restore +9999 HP, debuff max HP to 80): DONE
- Melee (X, 0.1s, 50x10 at 20px offset, body hit detection, locked direction/input, stops on ground, falls in air, blue visual): DONE
- Knockback (0.25s lock): DONE
- Dash Item (Green, Y=592, CD -> 0.4s): DONE
- Grab Enemy (PATROL/CHASE/DEAD states, raycast cliff/wall, 100px chase radius, wall-jump, CORPSE→Key pickup): DONE
- QTE Struggle (Space/E spam, success pushback, fail death): PLANNED
- Player Key Inventory (keys[], collect_key(), key_collected signal): DONE
- HUD Key Display (KeyLabel, shows collected keys): DONE
- Wall Slide/Jump: PLANNED
- Sandbox (Procedural 60x20 grid, 32x32 tiles brown/black, floor/ceiling/walls/4 platform rows): DONE
- Red Bean Static Enemy: DELETED
- Patrol/Chase/Corpse Enemy: DONE
- Dash Upgrade Item: DONE
- 2D Lighting & Shadows (CanvasModulate Color(0.25,0.18,0.35), Player PointLight2D 384px radial, Tile LightOccluder2D square polygon, shadow opacity 70%, background ColorRect deep purple): DONE
- Enemy Spawner (procedural ground coordinates spawner, maintains 5 alive GrabEnemies, >300px distance threshold): DONE
