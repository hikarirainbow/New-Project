# PROTOTYPE STORY & ENDINGS DESIGN
(Thiết kế Cốt truyện & Phân nhánh Kết thúc - Phiên bản Prototype)

Tài liệu này tóm tắt cấu trúc cốt truyện và các phân nhánh kết thúc (Endings) của Prototype, đồng thời tích hợp các cơ chế Gameplay cốt lõi để tạo ra sự cộng hưởng tối đa giữa lối chơi hành động và yếu tố kể chuyện H-18.

---

## 1. Cốt Truyện Tổng Quan (Narrative Premise)

* **Nhân vật chính:** Một cô thầy cúng (Miko/Shaman) mang trong mình dòng máu thanh tẩy thần thánh.
* **Biến cố kích hoạt (Inciting Incident):** Để cứu người bạn thân thuở nhỏ khỏi một dịch bệnh quỷ dị đang ăn mòn linh hồn, cô phải lún sâu vào thế giới quỷ giới (Demon Realm) để tìm thuốc giải.
* **Giao kèo bóng tối:** Tại ranh giới quỷ giới, cô gặp **Quỷ dục vọng (Demon of Lust)** - một trong Thất Đại Tội. Hiện con quỷ này đang bị cô lập và lép vế do các cuộc tranh giành quyền lực nội bộ.
  * *Thỏa thuận:* Con quỷ ban cho cô sức mạnh bóng tối (Dash, Combo ẩn, Sức mạnh Dục vọng) và hứa sẽ cứu mạng người bạn thuở nhỏ.
  * *Điều kiện:* Cô phải săn lùng và mang về **đầu của 6 con quỷ đại tội khác** (Gluttony, Wrath, Pride, Sloth, Greed, Envy) để giúp nó thống nhất quỷ giới.

---

## 2. Phân Nhánh 3 Kết Thúc (Multi-Endings)

Để tạo động lực chơi lại nhiều lần (Replayability) và thỏa mãn các tệp người chơi khác nhau, game sẽ có 3 kết thúc đặc trưng:

### 🖤 Ending 1: "Đồ Chơi Của Quỷ" (Corrupted / Bad Ending)
* **Mô tả:** Cô thầy cúng hoàn toàn đánh mất nhân tính, tâm trí bị dục vọng quỷ dữ nuốt chửng. Cô trở thành nô lệ thể xác và món đồ chơi giải trí vĩnh viễn cho con Quỷ dục vọng đồng minh.
* **Tệp người chơi:** Dành cho những ai muốn trải nghiệm nội dung H-18 thuần túy nhất.
* **Điều kiện mở khóa:** Điểm Tỉnh Táo (`sanity`) cực thấp do thua trận liên tục, bị dính nhiều cảnh H hoặc lạm dụng quá đà năng lượng tha hóa của quỷ.

### 😈 Ending 2: "Chúa Quỷ Tối Cao" (Dark / Power-Fantasy Ending)
* **Mô tả:** Nhận ra bộ mặt thật đầy dối trá của Quỷ dục vọng sau khi hạ gục 6 đại tội, cô thầy cúng quyết định "hóa quỷ" hoàn toàn. Cô quay lưng đồ sát luôn con Quỷ dục vọng đồng minh, cướp đoạt ngai vàng và trở thành **Chúa Quỷ tối cao duy nhất** thống trị quỷ giới với quyền năng vô hạn.
* **Tệp người chơi:** Dành cho những ai đam mê hành động hardcore, sức mạnh bá đạo và phong cách báo thù đen tối.
* **Điều kiện mở khóa:** Điểm Tỉnh Táo ở mức trung bình/cao, và người chơi chủ động chọn **"Đồ sát đồng minh"** trước trận chiến cuối cùng (Kích hoạt Boss ẩn: Quỷ Dục Vọng).

### 👼 True Ending: "Thánh Nữ U Buồn" (The Tragic Saint / Bittersweet Ending)
* **Mô tả:** Cô thầy cúng kiên cường giữ vững đức tin thanh khiết, vượt qua mọi cám dỗ. Ở trận chiến cuối cùng, cô chấp nhận **hy sinh toàn bộ thần lực và linh hồn** để thanh tẩy dịch bệnh cho người bạn. Linh hồn người bạn được giải thoát hoàn toàn, nhưng thể xác của cậu ấy đã không chịu nổi và qua đời trước đó. Cô được thần linh phong làm Thánh nữ, thoát khỏi quỷ giới và trở về thế giới loài người để thăm mộ người bạn thuở nhỏ trong cô độc u sầu.
* **Tệp người chơi:** Dành cho những game thủ yêu thích cốt truyện nghệ thuật, cảm xúc sâu sắc và bi tráng (Bittersweet).
* **Điều kiện mở khóa:** Giữ điểm Tỉnh Táo ở mức cao, hoàn thành chuỗi nhiệm vụ **"Sám hối / Thanh tẩy"** trước trận chiến cuối và chọn hy sinh bản thân để cứu bạn.

---

## 3. Tích Hợp Gameplay & Kể Chuyện (Narrative-Gameplay Integration)

Để cốt truyện không bị tách rời khỏi lối chơi, hệ thống sẽ sử dụng một biến số ẩn: **Điểm Tỉnh Táo (`sanity_points`)** từ `0` đến `100`.

### A. Cơ chế Tha Hóa & Sức Mạnh (Lust & Corruption)
* **High Risk - High Reward:** Khi sử dụng các kỹ năng đặc biệt của quỷ (như Lướt bất tử, Combo gây sát thương lớn), thanh Tha hóa tăng lên (điểm `sanity` giảm).
* Sát thương của người chơi tăng tỷ lệ thuận với độ tha hóa (giúp người chơi cảm thấy bá đạo đúng kiểu "Human vs God").
* **Cái giá phải trả:** Khi tha hóa càng cao, người chơi sẽ nhận thêm sát thương từ quái vật và **rất dễ bị quái vật vồ trúng khống chế** (tăng tần suất kích hoạt cơ chế QTE thoát hiểm).

### B. Cơ chế QTE & Cảnh H-18
* Khi bị quái vật vồ trúng, người chơi phải spam phím QTE (A/D) cực nhanh để đẩy quái ra:
  * **QTE Thành công:** Đẩy quái ra, hồi một lượng máu nhỏ, phục hồi một chút `sanity`.
  * **QTE Thất bại / Bị hạ gục:** Kích hoạt cảnh H-18 trực tiếp từ quái/boss đó. Sau cảnh H, người chơi bị trừ mạnh điểm `sanity`.

### C. Cơ chế Chuộc Tội (Redemption)
* Tránh tình trạng người chơi True Ending bị "tước quyền lợi" xem cảnh H.
* Người chơi có thể tự do xem các cảnh H trong quá trình đi màn, nhưng trước trận chiến quyết định, họ có thể đến các **"Hồ Nước Thánh"** hoặc làm nhiệm vụ sám hối ẩn để thanh lọc bản thân, khôi phục lại điểm `sanity` nhằm hướng tới True Ending nếu muốn.

---

## 4. Kế Hoạch Triển Khai Cho Mẫu Thử (Prototype Scope)

Để tránh bị vỡ scope (bể dự án), việc phát triển sẽ tập trung theo các giai đoạn:
1. **Giai đoạn 1 (Hiện tại - Đã xong):** Hoàn thiện bộ điều khiển di chuyển mượt mà (Walk, Jump, Dash, Climb, 3-hit combo, QTE, và hệ thống Lighting/Shadows).
2. **Giai đoạn 2 (Mục tiêu tiếp theo):**
   * Lập trình biến số ẩn `sanity_points` hoạt động liên thông với máu và QTE.
   * Xây dựng **1 màn chơi hoàn chỉnh đầu tiên** (Đại diện cho Đại tội Phẫn Nộ - Wrath) kèm 1 Boss Wrath có AI xả chiêu đầy đủ.
   * Thiết kế menu hội thoại lựa chọn rẽ nhánh tại Safe Hub của Quỷ dục vọng.
