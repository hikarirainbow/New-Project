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
- Dash (0.2s, 0.18s iframe, 0.02s lerp, 0.8s CD): DONE
- Physics Layers: L1=Env, L2=Player, L3=Enemy, L4=Hitbox, L8=Item
- HP (100 HP max, HUD bar Tween): DONE
- Respawn (Fade 0.5s, restore +9999 HP, debuff max HP to 80): DONE
- Melee (X, 0.1s, 50x10 at 20px offset, blue visual): DONE
- Knockback (0.25s lock): DONE
- Dash Item (Green, Y=464, CD -> 0.4s): DONE
- Grab Enemy (Patrol/Dead states, raycast cliff/wall): DONE
- QTE Struggle (Space/E spam, success pushback, fail death): PLANNED
- Wall Slide/Jump: PLANNED
- Sandbox (Platforms, Red Bean, Patrol Enemy, Dash Upgrade): DONE
