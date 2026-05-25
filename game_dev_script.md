# Kịch Bản Phát Triển Game (Game Development Script)

Tài liệu này đóng vai trò là **Kịch bản Phát triển (Game Dev Script)** và **Tài liệu Thiết kế Game (GDD)** cốt lõi của dự án Metroidvania. Dữ liệu tại đây sẽ được cập nhật liên tục để định hình mã nguồn và các tệp cảnh trong dự án.

---

## 1. Bản Tóm Tắt Dự Án (Project Pitch)
* **Tên dự án (Tạm thời):** *[Điền tên game tại đây]*
* **Thể loại:** Metroidvania, Action-Platformer, Mature (H18 Defeated Scene)
* **Ý tưởng cốt lõi (Elevator Pitch):**
  *[Tóm tắt ngắn gọn trải nghiệm cốt lõi của game trong 2-3 câu]*

---

## 2. Kịch Bản Thiết Kế Nhân Vật & Kỹ Năng (Player Mechanics Script)

### A. Bộ Di Chuyển Cơ Bản
* **Tốc độ di chuyển mặt đất:** `[Thông số px/s]`
* **Lực nhảy (Jump Force):** `[Thông số px/s]`
* **Trọng lực thông thường (Gravity):** `[Thông số]`

### B. Kịch Bản Móc Dây (Grappling Hook Logic)
* **Trạng thái kích hoạt:** Người chơi nhấn phím chỉ định (`grapple_hook`), dò điểm bám bằng Raycast2D.
* **Quy tắc kéo vật lý:**
  * Hướng kéo: Từ tọa độ người chơi tới điểm va chạm.
  * Tốc độ kéo: `[Thông số px/s]`
  * Điều kiện ngắt dây: Nhả phím, chạm đất, hoặc nhảy giữa chừng.

---

## 3. Kịch Bản Cảnh Thua Cuộc (Defeated Scene Hook Script)

### A. Trigger Hook (Bắt Sự Kiện)
* **Điều kiện:** Chỉ số `health` của Player giảm về `0`.
* **Quy trình kích hoạt:**
  1. Trạng thái của Player chuyển sang `DEFEATED` (vô hiệu hóa hoàn toàn điều khiển phím).
  2. Kích hoạt hiệu ứng camera rung lắc nhẹ (screen shake) và màn hình tối dần (fade to black).
  3. Phát tín hiệu `player_defeated` gửi tới `GameManager`.
  4. `GameManager` dừng vòng lặp game chính (Pause engine logic) và tải phân cảnh `defeat_scene.tscn`.

### B. Thiết Kế Trình Phát Cảnh Thua Cuộc (Defeat Scene Player)
* **Animation Sequence:**
  * Giai đoạn 1: Play Animation hoạt họa thất bại (placeholder).
  * Giai đoạn 2: Hiển thị bảng điều khiển UI Game Over mượt mà.
* **Giao diện UI lựa chọn:**
  * [Chơi lại từ Checkpoint gần nhất] -> Khởi động lại màn chơi và hồi máu.
  * [Thoát ra Menu chính]

---

## 4. Kịch Bản Thiết Kế Màn Chơi (Level Design Script)
* **Bản đồ thử nghiệm (Sandbox Level):**
  * Gồm phòng bắt đầu với các chướng ngại vật để thử nhảy.
  * Các móc treo trên trần để thử nghiệm cơ chế Grappling Hook.
  * Kẻ địch/Bẫy gây sát thương để thử nghiệm cơ chế Thua cuộc (Defeated Trigger).
