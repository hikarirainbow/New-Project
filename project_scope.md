# Phạm Vi Dự Án & Danh Sách Tính Năng Chi Tiết (Project Scope & Features)

Tài liệu này phân tách dự án game Metroidvania 2D Pixel Art thành các giai đoạn phát triển và tính năng cụ thể. Đây là bản danh sách chi tiết (Backlog) để chúng ta theo dõi tiến độ lập trình.

---

## Giai Đoạn 1: Hệ Thống Vật Lý & Di Chuyển (Core Physics & Movement)

### 1. Bộ Điều Khiển Nhân Vật 2D (Player Controller 2D)
* **Di chuyển cơ bản (Walk):**
  * Di chuyển trái/phải bằng phím `A`/`D` hoặc phím mũi tên.
  * Có gia tốc (Acceleration) khi bắt đầu chạy và giảm tốc (Friction) khi dừng lại để tránh cảm giác trơn trượt.
* **Nhảy & Rơi (Jump & Fall):**
  * Nhảy bằng phím `Space` với lực nhảy có thể điều chỉnh (giữ phím nhảy cao hơn, thả phím nhảy thấp hơn).
  * Áp dụng trọng lực lớn hơn khi nhân vật đang rơi xuống (Fall Gravity) để cảm giác nhảy chắc chắn hơn.
* **Lướt nhanh (Dash - Dự kiến):**
  * Phím `Shift` hoặc nhấp đúp hướng để lướt nhanh theo chiều ngang.
  * Miễn nhiễm sát thương (Invulnerability frames) trong thời gian lướt.
* **Bám/Nhảy tường (Wall Slide/Wall Jump - Dự kiến):**
  * Khi áp sát tường, nhân vật trượt xuống chậm hơn và có thể nhảy bật ra hướng ngược lại.

### 2. Thiết Lập Va Chạm Vật Lý (Physics Layers)
* Phân chia rõ ràng các lớp va chạm trong Godot:
  * `Layer 1`: Môi trường (Nền đất, tường, trần).
  * `Layer 2`: Người chơi (Player).
  * `Layer 3`: Kẻ địch (Enemies).
  * `Layer 4`: Hộp nhận sát thương của người chơi (Player Hitbox).
  * `Layer 5`: Hộp gây sát thương của kẻ địch (Enemy Hurtbox).

---

## Giai Đoạn 2: Chỉ Số Sinh Tồn & Hệ Thống Chiến Đấu (Stats & Combat)

### 1. Chỉ Số Nhân Vật (Player Stats)
* **Hệ thống máu (Health):**
  * `current_health` (Máu hiện tại) và `max_health` (Máu tối đa, mặc định `100`).
* **Trạng thái Suy Yếu (Debuff):**
  * Khi hồi sinh sau khi thua cuộc, nhân vật chịu Debuff: Giảm `20%` sức tấn công và Giảm `-20` máu tối đa.
  * Có cơ chế xóa Debuff khi tương tác với Điểm lưu game (Save Point/Sanctuary).

### 2. Hệ Thống Chiến Đấu Cơ Bản (Basic Combat)
* **Đòn đánh thường (Melee Attack):**
  * Nhấn chuột trái để vung kiếm cận chiến.
  * Tạo CollisionShape ngắn phía trước nhân vật để quét trúng kẻ địch.
  * Kẻ địch trúng đòn bị giật lùi (Knockback) và nháy đỏ.
* **Hệ thống nhận sát thương của người chơi:**
  * Khi va chạm với quái vật thường: mất máu và bị đẩy lùi ngắn.

---

## Giai Đoạn 3: Hệ Thống Kháng Cự & Bấm Phím Nhanh (Grab & QTE System)

### 1. Trạng Thái Bị Khống Chế (Grabbed State)
* **Kẻ địch đặc biệt (Grab-type Enemy):**
  * Quái vật có một vùng phát hiện tấn công đặc biệt (Grab Area). Khi người chơi đi vào vùng này, quái vật sẽ lao vào tóm lấy người chơi thay vì gây sát thương thông thường.
* **Chuyển đổi trạng thái:**
  * Nhân vật chuyển sang trạng thái `GRABBED`.
  * Khóa hoàn toàn khả năng di chuyển và tấn công của người chơi.
  * Chạy hoạt họa nhân vật bị quái vật đè/khống chế.

### 2. Cơ Chế QTE Struggle (Nhấn Phím Kháng Cự)
* **Thanh trạng thái Struggle Bar:**
  * Xuất hiện một thanh trượt UI phía trên đầu nhân vật.
  * Có mốc thời gian đếm ngược (ví dụ: `5 giây`).
* **Logic bấm phím:**
  * Người chơi phải nhấn phím `Space` hoặc `E` liên tục và nhanh nhất có thể.
  * Mỗi lần nhấn phím thành công sẽ đẩy thanh đo Struggle Bar lên.
  * Thanh đo tự động tụt giảm dần theo thời gian (decay rate) để tạo áp lực.
* **Kết quả:**
  * **Thành công (QTE Success):** Thanh đo đầy trước khi hết giờ -> Kích hoạt đòn phản công, đẩy kẻ địch ra xa, gây cho chúng sát thương nhẹ, người chơi được giải thoát và có 1 giây miễn sát thương để hồi phục vị trí.
  * **Thất bại (QTE Failure):** Hết giờ mà thanh đo chưa đầy -> Máu của nhân vật giảm ngay lập tức về 0, chuyển sang trạng thái `DEFEATED` và bắt đầu chuyển cảnh.

---

## Giai Đoạn 4: Trình Phát Cảnh Thua Cuộc & Chuyển Cảnh (Defeat Scene & Transition)

### 1. Quản Lý Chuyển Cảnh Toàn Cục (GameManager)
* Autoload `GameManager` duy trì trạng thái nhân vật khi chuyển giao giữa các màn chơi.
* Lắng nghe tín hiệu `player_defeated`.

### 2. Phân Cảnh Bị Đánh Bại (Defeat Scene)
* Tải tệp cảnh `defeat_scene.tscn`.
* Làm mờ màn hình chơi game (Fade out) và chuyển tiếp camera.
* Chạy các phân cảnh hoạt họa Pixel Art (trước mắt sử dụng các hình ảnh placeholder chuyển động kèm chữ mô tả kịch bản).
* Hiển thị bảng điều khiển UI Game Over:
  * **[Retry]:** Tải lại cảnh màn chơi tại checkpoint gần nhất, áp dụng Debuff lên nhân vật.
  * **[Main Menu]:** Quay lại màn hình chính của game.

---

## Giai Đoạn 5: Thiết Kế Màn Chơi Thử Nghiệm (Sandbox Room)

### 1. Bản Đồ Kiểm Thử (Sandbox Map)
* Tạo màn chơi thử nghiệm sử dụng TileMap cơ bản:
  * Vùng đất bằng phẳng để chạy thử tốc độ di chuyển.
  * Các bậc thềm cao thấp để thử nghiệm cơ chế nhảy.
  * Một Điểm Lưu Game (Save Point) để hồi phục máu và xóa Debuff.
* **Bố trí Kẻ địch:**
  * 1 Kẻ địch tuần tra thông thường (để kiểm tra chiến đấu, sát thương).
  * 1 Kẻ địch đặc biệt có khả năng chụp tóm (để kiểm tra cơ chế QTE/Defeat).
