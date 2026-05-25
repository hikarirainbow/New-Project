# Kịch Bản Phát Triển Game (Game Development Script)

Tài liệu này đóng vai trò là **Kịch bản Phát triển (Game Dev Script)** và **Tài liệu Thiết kế Game (GDD)** cốt lõi của dự án Metroidvania. Dữ liệu tại đây sẽ được cập nhật liên tục để định hình mã nguồn và các tệp cảnh trong dự án.

---

## 1. Bản Tóm Tắt Dự Án (Project Pitch)
* **Tên dự án (Tạm thời):** *Project Defeated (Sinisistar-inspired Metroidvania Demo)*
* **Thể loại:** Metroidvania, 2D Pixel Art, Action-Platformer, Mature (H18 Defeated Scene + QTE)
* **Ý tưởng cốt lõi (Elevator Pitch):**
  Một trò chơi đi cảnh hành động 2D Pixel Art tập trung vào khám phá u ám và chiến đấu sinh tồn. Khi người chơi bị quái vật khống chế hoặc hết máu, một cơ chế QTE (Quick Time Event) sẽ được kích hoạt để người chơi cố gắng vùng vẫy thoát thân. Nếu thất bại, nhân vật sẽ chịu cảnh bị đánh bại và hồi sinh kèm theo bùa hại (debuff).

---

## 2. Kịch Bản Thiết Kế Nhân Vật & Kỹ Năng (Player Mechanics Script)

### A. Bộ Di Chuyển Cục Bộ
* **Tốc độ di chuyển mặt đất (SPEED):** `200 px/s` (Gia tốc `1000`, Ma sát dừng `1200`)
* **Lực nhảy (Jump Force):** `-380 px/s` (Trọng lực rơi tự do `980 * 1.5` để tăng lực rơi)
* **Lướt nhanh (Dash - Phím C):**
  * Thời gian lướt: `0.2` giây.
  * 0.18 giây đầu (9/10): Tốc độ tăng vọt lên `DASH_SPEED = 600 px/s`, khóa trục dọc Y, và **miễn nhiễm sát thương** (`is_invincible = true`).
  * 0.02 giây cuối (1/10): Tắt miễn nhiễm, nội suy vận tốc (Lerp) mượt mà về tốc độ di chuyển mong muốn và áp dụng lại trọng lực.
  * Hồi chiêu lướt (`dash_cooldown`): mặc định `0.8` giây.

### B. Chỉ số sinh tồn
* **Máu tối đa (Max Health):** `100`
* **Trạng thái Debuff sau khi thua cuộc:** Giảm `-20` máu tối đa (còn lại tối đa 80 HP) khi hồi sinh.

### C. Tấn công cận chiến (Attack - Phím X)
* **Thời gian ra chiêu:** `0.1` giây.
* **Quy chuẩn Hitbox:** Kích hoạt hộp va chạm Area2D dài `50px` cao `10px` đặt lệch tâm nhân vật `20px` về phía trước (Tâm X = `+45px` hoặc `-45px` tùy hướng quay mặt).
* **Vẽ chỉ báo visual:** Vẽ hình chữ nhật màu xanh dương bán trong suốt trong thời gian ra chiêu.

---

## 3. Kịch Bản Vật Phẩm (Item Script)

### A. Hạt nâng cấp Dash Cooldown (Green Circle Item)
* **Đặc tính:** Hình tròn màu xanh lá cây đặt ở bên phải màn hình tại `(800, 464)`.
* **Hiệu ứng thu thập:** Gọi hàm nâng cấp `upgrade_dash_cooldown()` trên Player để **giảm vĩnh viễn 50% thời gian hồi chiêu lướt** (`dash_cooldown = 0.4s`) và tự biến mất.

---

## 4. Kịch Bản Cảnh Thua Cuộc (Defeated Scene Hook Script)

### A. Trigger Hook & Cơ chế QTE (Bắt Sự Kiện)
1. **Điều kiện kích hoạt:**
   * Chỉ số `health` giảm về `0` do sát thương thường.
   * Hoặc bị dính đòn chụp/tóm đặc biệt từ quái vật (Grab Attack).
2. **Quy trình hoạt động:**
   * Trạng thái Player chuyển sang `GRABBED` (vô hiệu hóa nút di chuyển thông thường).
   * Màn hình kích hoạt thanh đo **QTE Struggle Bar**.
   * Người chơi phải nhấn phím chỉ định (phím `Space` hoặc `E`) thật nhanh để tăng thanh đo.
   * **Nếu QTE thành công:** Đẩy lùi kẻ địch, hồi lại một lượng máu nhỏ và tiếp tục chiến đấu.
   * **Nếu QTE thất bại:** Chuyển sang trạng thái `DEFEATED`, chạy hoạt họa thua cuộc đầy đủ, sau đó chuyển cảnh sang màn hình Restart kèm theo hiệu ứng **Debuff**.

### B. Thiết Kế Trình Phát Cảnh Thua Cuộc (Defeat Scene Player)
* **Animation Sequence:**
  * Màn hình mờ dần (Fade out to black) trong `0.5` giây bằng `ScreenFade` của HUD.
  * Hồi sinh Player tại điểm xuất phát (`spawn_point`), hồi lại `+9999` máu và áp dụng debuff (HP max = 80).
  * Làm sáng lại màn hình (Fade out) trong `0.5` giây để tiếp tục chơi.

---

## 5. Kịch Bản Thiết Kế Màn Chơi (Level Design Script)
* **Bản đồ thử nghiệm (Sandbox Level):**
  * Nền đất phẳng dài `1200px` cao `40px` tại Y = 500, có tường chắn 2 bên.
  * Đặt 1 kẻ địch hạt đậu đỏ tĩnh tại `(400, 464)`.
  * Đặt 1 hạt nâng cấp lướt màu xanh lá tại `(800, 464)`.
  * Đặt 1 quái vật Grab tuần tra *[Sắp triển khai]*.

---

## 6. Kịch Bản Hệ Thống Cài Đặt (Settings & Save System Script)

### A. Autoload InputManager
* **Chức năng:** Tải và lưu trữ các phím bấm dạng JSON tại `user://input_config.json`.
* **Cấu hình mặc định:**
  * `move_left` = A (65)
  * `move_right` = D (68)
  * `jump` = Space (32)
  * `dash` = C (67)
  * `attack` = X (88)

### B. Settings UI
* **Bật/Tắt:** Khi bấm phím `ESC`, trò chơi bị dừng (Pause), hiển thị UI Settings Menu và chuyển chuột sang chế độ `MOUSE_MODE_VISIBLE`.
* **2 Chức năng bổ trợ:**
  * **Audio Mute:** Cho phép bật/tắt toàn bộ âm thanh (Mute/Unmute AudioServer bus 0).
  * **Reset Controls:** Khôi phục cấu hình phím mặc định của InputManager, lưu đè file JSON.
* **Giao diện & Hover:** Các nút bấm phẳng trong suốt hiển thị tên phím gán. Khi rê chuột vào (Hover), tạo một đường viền dưới màu xanh sáng bóng (`StyleBoxFlat` với `border_width_bottom = 2px`).
* **Ẩn chuột:** Chuột mặc định bị ẩn và bắt giữ (`Input.mouse_mode = Input.MOUSE_MODE_CAPTURED`) khi chơi game bình thường.
