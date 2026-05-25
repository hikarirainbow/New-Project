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

### A. Bộ Di Chuyển Cơ Bản (Thử nghiệm trước)
* **Tốc độ di chuyển mặt đất:** `200 px/s`
* **Lực nhảy (Jump Force):** `-350 px/s`
* **Trọng lực thông thường (Gravity):** `980 px/s²`
* **Kỹ năng dự kiến (mở rộng sau):** Dash (lướt nhanh), Wall Jump (nhảy tường), Double Jump (nhảy đúp).

### B. Chỉ số sinh tồn
* **Máu tối đa (Max Health):** `100`
* **Trạng thái Debuff sau khi thua cuộc:** Giảm `20%` sức tấn công hoặc `-20` máu tối đa cho đến khi sử dụng vật phẩm thanh tẩy hoặc lưu game tại điểm an toàn.

---

## 3. Kịch Bản Cảnh Thua Cuộc (Defeated Scene Hook Script)

### A. Trigger Hook & Cơ chế QTE (Bắt Sự Kiện)
1. **Điều kiện kích hoạt:**
   * Chỉ số `health` giảm về `0` do sát thương thường.
   * Hoặc bị dính đòn chụp/tóm đặc biệt từ quái vật (Grab Attack).
2. **Quy trình hoạt động:**
   * Trạng thái Player chuyển sang `GRABBED` (vô hiệu hóa nút di chuyển thông thường).
   * Màn hình kích hoạt thanh đo **QTE Struggle Bar**.
   * Người chơi phải nhấn phím chỉ định (ví dụ: `Space` hoặc `E`) thật nhanh để tăng thanh đo.
   * **Nếu QTE thành công:** Đẩy lùi kẻ địch, hồi lại một lượng máu nhỏ và tiếp tục chiến đấu.
   * **Nếu QTE thất bại:** Chuyển sang trạng thái `DEFEATED`, chạy hoạt họa thua cuộc đầy đủ, sau đó chuyển cảnh sang màn hình Restart kèm theo hiệu ứng **Debuff**.

### B. Thiết Kế Trình Phát Cảnh Thua Cuộc (Defeat Scene Player)
* **Animation Sequence:**
  * Khung cảnh chuyển động mờ dần hoặc rung lắc dữ dội.
  * Chạy hoạt họa Pixel Art của cảnh thua cuộc (placeholder).
* **Giao diện UI lựa chọn:**
  * [Khởi động lại tại Checkpoint] -> Hồi sinh với 80% máu và dính hiệu ứng Debuff.
  * [Thoát ra Menu chính]

---

## 4. Kịch Bản Thiết Kế Màn Chơi (Level Design Script)
* **Bản đồ thử nghiệm (Sandbox Level):**
  * Gồm phòng bắt đầu với nền tảng để chạy nhảy.
  * Một vật thể bẫy/kẻ địch tĩnh có khả năng gây sát thương hoặc tóm người chơi để thử nghiệm cơ chế QTE/Defeat.

