# Phạm Vi Dự Án & Danh Sách Tính Năng Chi Tiết (Project Scope & Features)

Tài liệu này phân tách dự án game Metroidvania 2D Pixel Art thành các giai đoạn phát triển và tính năng cụ thể. Đây là bản danh sách chi tiết (Backlog) để chúng ta theo dõi tiến độ lập trình.

---

## Giai Đoạn 1: Hệ Thống Vật Lý & Di Chuyển (Core Physics & Movement)

### 1. Bộ Điều Khiển Nhân Vật 2D (Player Controller 2D)
* `[x]` **Di chuyển cơ bản (Walk):**
  * Di chuyển trái/phải bằng phím `A`/`D`.
  * Có gia tốc (Acceleration = 1000) và giảm tốc (Friction = 1200) để di chuyển mượt mà.
* `[x]` **Nhảy & Rơi (Jump & Fall):**
  * Nhảy bằng phím `Space` với lực nhảy `JUMP_VELOCITY = -380`.
  * Áp dụng trọng lực rơi nhanh hơn (`active_gravity = gravity * 1.5` khi đi xuống) giúp cảm giác nhảy nặng tay, chắc chắn.
* `[x]` **Lướt nhanh (Dash):**
  * Sử dụng phím **`C`** để lướt nhanh theo chiều ngang.
  * Tổng thời gian lướt là `0.2` giây.
  * `0.18` giây đầu (9/10): Tốc độ tăng gấp 3 (`DASH_SPEED = 600 px/s`), khóa chiều dọc, và **miễn nhiễm hoàn toàn sát thương (i-frames)**.
  * `0.02` giây cuối (1/10): Tắt miễn nhiễm, nội suy vận tốc (Lerp) mượt mà về tốc độ đích dựa trên phím giữ, trả lại trọng lực.
  * Thời gian hồi chiêu mặc định: `0.8` giây.
* `[ ]` **Bám/Nhảy tường (Wall Slide/Wall Jump - Dự kiến cho tương lai):**
  * Trượt tường chậm hơn và nhảy bật ngược ra khi áp sát tường.

### 2. Thiết Lập Va Chạm Vật Lý (Physics Layers)
* `[x]` Phân chia rõ các lớp va chạm trong Godot:
  * `Layer 1` (Mask 2): Môi trường (Nền đất, tường).
  * `Layer 2` (Mask 1, 4, 8): Người chơi (Player).
  * `Layer 3`: Kẻ địch (Enemies).
  * `Layer 4` (Mask 2): Hộp gây/nhận sát thương của kẻ địch/bẫy.
  * `Layer 8` (Mask 2): Vật phẩm (Items).

---

## Giai Đoạn 2: Chỉ Số Sinh Tồn & Hệ Thống Chiến Đấu (Stats & Combat)

### 1. Chỉ Số Nhân Vật (Player Stats)
* `[x]` **Hệ thống máu (Health):**
  * Máu hiện tại (`current_health`) và máu tối đa (`max_health = 100`).
  * Có thanh máu UI HUD hiển thị trực quan (`HP: X/Y`) góc trên bên trái, rút máu co lại mượt mà bằng hiệu ứng Tween `0.25 giây`.
* `[x]` **Trạng thái Suy Yếu (Debuff):**
  * Khi hồi sinh, nhân vật chịu Debuff: Giảm `-20` máu tối đa (chỉ còn tối đa 80 HP).
* `[ ]` **Xóa Debuff (Dự kiến):**
  * Xóa Debuff khi tương tác với Điểm lưu game (Save Point).

### 2. Hệ Thống Chiến Đấu Cơ Bản (Basic Combat)
* `[x]` **Đòn đánh cận chiến (Melee Attack):**
  * Nhấn phím **`X`** để chém cận chiến trong `0.1` giây.
  * Kích hoạt `AttackArea` (`Area2D` với `CollisionShape2D` cỡ `50x10`) cách tâm nhân vật `20px` về phía trước.
  * Có hiển thị vệt chém visual hình chữ nhật màu xanh dương bán trong suốt trong `0.1` giây nhờ hàm `_draw()`.
  * Gây `20` sát thương lên kẻ địch trúng đòn (Layer 4).
* `[x]` **Nhận sát thương & Đẩy lùi (Knockback):**
  * Khi va chạm với kẻ địch/bẫy đỏ (Layer 4): bị trừ máu, nảy nhẹ lên và đẩy lùi ra xa nguồn sát thương.
  * Khóa phím điều khiển trong `0.25` giây (`knockback_timer`) để tăng cảm giác va đập.

---

## Giai Đoạn 3: Hệ Thống Vật Phẩm (Item System)

* `[x]` **Vật phẩm giảm hồi chiêu Dash (Green Circle Item):**
  * Đặt tại tọa độ `(800, 464)`, đối xứng với quái vật đỏ.
  * Vẽ hình tròn xanh lá đường kính `24px` viền đen.
  * Khi Player chạm vào: kích hoạt hàm `upgrade_dash_cooldown()` trên Player để **giảm vĩnh viễn 1/2 thời gian hồi chiêu Dash** (từ `0.8s` xuống `0.4s`) và tự hủy (`queue_free()`).

---

## Giai Đoạn 4: Grab & QTE System (Khống chế & Nhấn phím giải thoát)

### 1. Trạng Thái Bị Khống Chế (Grabbed State)
* `[ ]` **Kẻ địch tóm (Grab-type Enemy):**
  * Quái vật tuần tra có vòng phát hiện đặc biệt. Khi chạm vào sẽ đưa Player vào trạng thái `GRABBED` thay vì gây sát thương bình thường.
* `[ ]` **Khóa điều khiển:**
  * Vô hiệu hóa phím bấm chạy/nhảy/lướt/chém thường của Player.

### 2. Cơ Chế QTE Struggle
* `[ ]` **Struggle Bar UI:**
  * Xuất hiện thanh đo QTE trên đầu Player kèm thời gian đếm ngược (ví dụ 5s).
* `[ ]` **Spam nút giải thoát:**
  * Người chơi nhấn nhanh phím `Space` hoặc `E` liên tục để tăng thanh đo (thanh đo tự động giảm dần theo thời gian).
* `[ ]` **Kết quả:**
  * **QTE Thành công:** Đẩy lùi kẻ địch, hồi nhẹ máu, thoát về trạng thái `MOVE`.
  * **QTE Thất bại:** Máu lập tức về `0`, chuyển trạng thái `DEFEATED` và bắt đầu hồi sinh.

---

## Giai Đoạn 5: Hồi Sinh & Chuyển Cảnh (Respawn & Fade Transitions)

* `[x]` **Màn hình tối đen (Screen Fade to Black):**
  * Thêm màn chắn `ScreenFade` (`ColorRect` đen bán trong suốt) phủ trên HUD.
  * Khi Player chết (`player_defeated`), dùng Tween làm tối đen toàn màn hình trong `0.5` giây.
* `[x]` **Hồi sinh hồi máu:**
  * Đưa Player trở lại điểm xuất phát (`spawn_point = global_position` lúc load game) và triệt tiêu vận tốc.
  * **Hồi phục hoàn toàn sinh lực:** Tăng `+9999` máu để đầy bình trước khi áp dụng Debuff (80 HP tối đa).
  * Chờ `0.2` giây rồi dùng Tween làm sáng màn hình trở lại trong `0.5` giây.

---

## Giai Đoạn 6: Thiết Kế Màn Chơi Thử Nghiệm (Sandbox Room)

### 1. Bản Đồ Kiểm Thử (Sandbox Map)
* `[x]` **Bề mặt địa hình:** Mặt đất phẳng dài xanh sẫm tại tọa độ Y = 500, có tường chặn 2 bên để giữ Player.
* `[x]` **Bố trí Kẻ địch tĩnh (Hạt đậu đỏ):** Đặt tại `(400, 464)`. Gây `15` sát thương và kích hoạt đẩy lùi khi Player đụng phải. In ra thông báo nhận sát thương khi bị chém trúng.
* `[x]` **Bố trí Vật phẩm nâng cấp (Hạt xanh lá):** Đặt tại `(800, 464)`. Giảm nửa thời gian hồi Dash khi ăn được.
* `[x]` **Bố trí Kẻ địch tóm (Grab Enemy):** *[Sắp triển khai]*

---

## Giai Đoạn 7: Hệ Thống Cài Đặt & Lưu Cấu Hình (Settings & Save System)

* `[x]` **Menu Cài Đặt (ESC Key):**
  * Kích hoạt bất kỳ lúc nào bằng phím `ESC`.
  * Làm ngừng hoàn toàn thời gian game (Pause) nhưng bản thân Menu vẫn hoạt động (`process_mode = PROCESS_MODE_ALWAYS`).
  * Giao diện u ám bán trong suốt (`StyleBoxFlat_panel`), có nhãn tiêu đề và danh sách điều khiển dạng lưới.
* `[x]` **Đổi Nút Điều Khiển (Key Remapping):**
  * Nhấp vào một nút phím để bắt đầu chờ nhận diện phím mới (`[ Nhấn phím bất kỳ ]`).
  * Tự động áp dụng phím mới vào `InputMap` ngay lập tức.
  * Tự động lọc phím `ESC` để tránh lỗi khóa phím hệ thống.
* `[x]` **Lưu & Tải Bằng JSON (Tối ưu nhất for Key-Value):**
  * Cấu hình lưu trữ tại `user://input_config.json`.
  * Tự động kiểm tra file, tạo cấu hình mặc định (A/D/Space/C/X) nếu chưa có hoặc tự tải ở lần chạy kế tiếp.
* `[x]` **Tính Năng Bổ Trợ (Mute & Reset):**
  * **Chức năng 1 (Âm thanh):** Bật/Tắt âm thanh toàn cục (Mute/Unmute Audio Server).
  * **Chức năng 2 (Đặt lại phím):** Khôi phục toàn bộ phím bấm về mặc định ban đầu.
* `[x]` **Hiệu Ứng Rê Chuột (Hover Highlight):**
  * Các nút trong menu có hiệu ứng dòng kẻ chân màu xanh sáng (`StyleBoxFlat_btn_hover` với viền dưới `2px`) khi đưa chuột vào.
* `[x]` **Quản Lý Con Trỏ Chuột (Cursor Capture):**
  * Khi chơi game: Chuột hoàn toàn bị ẩn và bắt giữ trong màn hình game (`Input.mouse_mode = Input.MOUSE_MODE_CAPTURED`).
  * Khi mở Menu (ESC): Chuột hiện lên để thao tác click (`Input.mouse_mode = Input.MOUSE_MODE_VISIBLE`).
