# Godot Project: Project Vertical Factory (ONI-Style)

## 🎯 Project Vision
Xây dựng một trò chơi mô phỏng quản lý và tự động hóa (Colony Sim/Automation) với góc nhìn 2D mặt cắt (Side-scrolling). 
- **Cảm hứng:** Factorio (tự động hóa, dây chuyền) + Oxygen Not Included (quản lý nhân sự, đào hầm, vật lý chất lỏng/khí).
- **Core Loop:** Ra lệnh đào bới -> Thu thập tài nguyên -> Xây dựng máy móc/công trình -> Tự động hóa quy trình -> Mở rộng xuống lòng đất.

## 🛠 Technology Stack
- **Engine:** Godot 4.5 (Forward Plus)
- **Language:** GDScript (Strongly Typed)
- **Architecture:** 
    - **Entity Component System (ECS-lite):** Các Unit (Minion) hoạt động dựa trên State Machine và Behavior Tree đơn giản.
    - **Command Pattern:** Người chơi không điều khiển Unit, mà tạo ra các "Command" (Lệnh). Task Manager sẽ phân phối lệnh cho Unit rảnh rỗi.
    - **Grid-based System:** Mọi tương tác dựa trên lưới (Grid) và TileMap.

## 📂 Directory Structure (Planned Refactor)
```text
res://
├── assets/             
├── entities/           
│   └── units/          # (New) Minion/Drone scenes (AI Controlled)
│   └── buildings/      # (New) Các công trình (Máy đào, băng chuyền...)
├── systems/            # (New) Các hệ thống quản lý logic
│   ├── task_manager.gd # Quản lý hàng đợi công việc
│   ├── grid_manager.gd # Quản lý dữ liệu bản đồ logic
│   └── pathfinding.gd  # AStar2D cho Unit di chuyển
├── controllers/        # (New)
│   └── god_controller.gd # Camera RTS, con trỏ chuột, công cụ chọn vùng
├── maps/               
└── ui/                 
```

## 📏 Development Conventions
- **Unit of Measurement:** 1 Tile = 1 Meter (hoặc 1 Unit).
- **Balancing:** 
    - **Mining Speed:** Base speed = 0.2s (Fast paced).
    - **Tick Rate:** Logic update 10-20 lần/giây (UPS) để tối ưu khi quy mô lớn.

## 🚀 Current Status & Transition Plan

### 1. Legacy Systems (To be Refactored/Removed)
- **Direct Player Control (WASD):** Sẽ bị loại bỏ. Thay thế bằng RTS Camera Controller.
- **Player Node:** Sẽ chuyển đổi thành "Minion Unit" đầu tiên.
- **Physics Movement:** Sẽ chuyển sang NavigationAgent2D (hoặc AStar logic) thay vì Platformer Physics (Gravity/Jumping).

### 2. New Priorities
- **[Critical] RTS Camera:** Camera tự do, zoom in/out, panning bằng WASD/Chuột.
- **[Critical] Mouse Interaction:** Hover để hiện highlight ô lưới, Click/Drag để chọn vùng đào.
- **[Critical] Task System:** Hệ thống lưu trữ các ô cần đào.
- **[Critical] AI Worker:** Unit tự động đi đến ô cần đào -> thực hiện animation -> xóa ô.

## 📝 Next Steps (Prioritized from User Feedback)

### 🚨 Immediate Fixes
- **Fix Zoom:** Restore zoom functionality (lost in recent updates).

### 🆕 New Features (Sprint 1)
1.  **UI Enhancements:**
    *   Add a **"+" Button** (Top-Right) to spawn Minion units (currently duplicate of Player).
    *   Add a **"Dig" Button** next to the Spawn button.
2.  **Interaction Systems:**
    *   **Selection:** Implement Left-Click Drag to draw a **Blue Rectangle** for selecting multiple units.
    *   **Digging Command:**
        *   Workflow: Select Units -> Toggle Dig Mode -> Drag area to mark blocks.
        *   Mechanics: 
            *   Mining Range: 3 tiles.
            *   Mining Time: 0.2s.
            *   **AI:** If target is out of range, Unit must use Pathfinding to approach.
            *   **Visuals:** Draw the path the unit will take.

### 🛠 System Refactor
1.  Tách Camera ra khỏi Player, tạo `CameraController` độc lập.
2.  Chuyển đổi `Player` hiện tại thành `Unit` (Minion) có khả năng nhận lệnh.
3.  Viết `TaskSystem` (Global) để quản lý lệnh "Đào".

## 📚 Project History & Context
- **Last Update:** Processed requirements from `temp.docx` (Zoom fix, Spawn/Dig UI, Selection Box, Pathfinding basics).

## 💡 Technical API (Auto-generated)

### `entities/mobs/unit.gd`
- **Extends:** `CharacterBody2D`
- **Class Name:** `Unit`
- **Variables:**
    - `move_speed: float` (Export)
    - `gravity_scale: float` (Export)
    - `friction: float` (Export)
    - `jump_force: float` (Export)
    - `current_path: PackedVector2Array`
    - `current_target_point: Vector2`
- **Functions:**
    - `_ready() -> void`
    - `_physics_process(delta: float) -> void`
    - `apply_gravity(delta: float) -> void`
    - `set_path(path: PackedVector2Array) -> void`
    - `follow_path(delta: float) -> void`

### `entities/player/player_main.gd`
- **Extends:** `Node2D`
- **Class Name:** `PlayerMain`
- **Variables:**
    - `move_speed: float`, `zoom_speed: float` (Export)
    - `selected_units: Array[Node2D]`
    - `is_dig_mode: bool`
    - `game_manager: GameManager`
- **Functions:**
    - `select_units_in_area() -> void`
    - `mark_dig_area() -> void`
    - `issue_move_command(target_pos: Vector2) -> void`
    - `find_ground_below(pos: Vector2) -> Vector2`

### `systems/game_manager.gd`
- **Extends:** `Node2D`
- **Class Name:** `GameManager`
- **Variables:**
    - `astar: AStar2D`
    - `tile_map: TileMapLayer`
    - `dig_tasks: Dictionary`
- **Functions:**
    - `build_navigation_graph() -> void`
    - `get_path_cells(from: Vector2, to: Vector2) -> PackedVector2Array`
    - `add_dig_task(tile_pos: Vector2i) -> void`
    - `remove_dig_task(tile_pos: Vector2i) -> void`
    - `get_nearest_dig_task(unit_pos: Vector2) -> Vector2i`

### `maps/map_generator.gd`
- **Extends:** `TileMapLayer`
- **Class Name:** `MapGenerator`
- **Variables:**
    - `chunk_size: int` (Export)
    - `render_distance: int` (Export)
    - `noise_seed: int` (Export)
    - `loaded_chunks: Dictionary`
- **Functions:**
    - `generate_chunk(chunk_pos: Vector2i) -> void`
    - `spawn_unit_at_camera() -> void`
    - `find_safe_spawn_pos(x_column: int) -> Vector2`

### `ui/game_ui.gd`
- **Extends:** `CanvasLayer`
- **Signals:** `spawn_requested`, `dig_mode_toggled`
- **Functions:**
    - `_on_btn_spawn_pressed() -> void`
    - `_on_btn_dig_toggled(toggled_on: bool) -> void`
    - `update_coords(pos: Vector2) -> void`

### `systems/camera_controller.gd`
- **Extends:** `Node2D`
- **Functions:**
    - `handle_movement(delta: float) -> void`
    - `change_zoom(amount: float) -> void`

### `ui/stats_ui.gd`
- **Extends:** `CanvasLayer`
- **Variables:** `target_fps: int` (Export)

### `ui/debug_ui.gd`
- **Extends:** `CanvasLayer`
- **Functions:** `_on_h_slider_value_changed(value: float) -> void`