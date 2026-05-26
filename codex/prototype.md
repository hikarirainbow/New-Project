# LUSTGOD — PROTOTYPE DESIGN & LORE
(Tài liệu Thiết kế & Cốt truyện - Phiên bản Mẫu thử)

Tài liệu này định hình phong cách nghệ thuật, cấu trúc cốt truyện, các phân nhánh kết thúc (Endings) và lộ trình phát triển của dự án **Lustgod**. Dự án kết hợp lối chơi đi cảnh khám phá bán mở (Metroidvania) chất lượng cao với các cơ chế H-18 sâu sắc và bi tráng.

---

## 1. Tầm Nhìn Dự Án & Phong Cách Lối Chơi (Game Vision)

* **Tên dự án chính thức:** **Lustgod**
* **Cảm hứng cốt lõi:** Lối chơi khám phá chiều sâu, bản đồ đan xen rộng lớn, truy tìm bí mật cổ xưa và khiêu chiến thần quyền tương tự như *Hollow Knight* và *Silksong*.
* **Bầu không khí & Mỹ thuật:** Sử dụng tối đa thế mạnh đồ họa 2D hiện có (Ánh sáng tương phản cực cao, bóng tối bao trùm, và hiệu ứng đổ bóng đen Silhouette của quái vật). Thế giới loài quỷ không chỉ có sự gớm ghiếc, mà mang một nét u sầu, bi tráng của những tàn tích rêu phong cổ kính.

---

## 2. Cốt Truyện & Ý Tưởng Cựu Thần Già Cỗi (Fading Gods Lore)

* **Nhân vật chính:** Một cô thầy cúng (Miko/Shaman) mang trong mình dòng máu thanh tẩy thần thánh tinh khiết.
* **Khởi đầu (Inciting Incident):** Bạn thân thuở nhỏ bị nhiễm quỷ dịch ăn mòn linh hồn. Để tìm thuốc giải, cô dấn thân vào Quỷ Giới (Demon Realm) huyền bí.
* **Giao kèo với Quỷ Dực (Demon of Lust):** Cô gặp một trong Thất Đại Tội - Quỷ Dục Vọng, hiện đang bị thất thế và suy yếu do cuộc chiến vương quyền nội bộ.
  * *Hỗ trợ:* Nó trao cho cô năng lượng quỷ (Dash, Combo, phép thuật) để sinh tồn và hứa sẽ cứu bạn thân cô.
  * *Điều kiện:* Cô phải săn lùng đầu của **6 Cựu Thần Đại Tội** khác cai trị 6 vùng đất cổ xưa của Quỷ Giới.
* **Chủ đề Boss - Cựu Thần Già Cỗi (Fading Gods):**
  * Các con Boss Đại Tội không phải là những quái vật điên cuồng vô nghĩa. Họ từng là những vị thần vĩ đại cai trị Quỷ Giới thời hoàng kim, nay đang dần già cỗi, suy tàn và bị lãng quên trong lâu đài đổ nát của riêng họ.
  * Mỗi cuộc chiến với họ mang màu sắc u sầu, bi tráng. Kết liễu họ là giải thoát họ khỏi nỗi đau kéo dài hàng thiên niên kỷ của thời gian.

---

## 3. Phân Nhánh 3 Kết Thúc (Multi-Endings)

Mức độ tỉnh táo của nhân vật chính (`sanity_points`, từ 0 đến 100) sẽ quyết định kết cục của vương quốc **Lustgod**:

### 🖤 Ending 1: "Đồ Chơi Của Quỷ" (Corrupted Ending - Bad)
* **Chi tiết:** Cô thầy cúng hoàn toàn tha hóa dưới sự chi phối của dục vọng quỷ dữ. Cô trở thành nô lệ thể xác vĩnh viễn cho Quỷ Dục Vọng đồng minh, bị giam cầm nơi quỷ giới sâu thẳm.
* **Điều kiện:** Điểm `sanity` cực thấp (<30%) do thất bại quá nhiều hoặc lạm dụng quá đà quỷ lực.

### 😈 Ending 2: "Chúa Quỷ Tối Cao" (Sovereign Demon Ending - Dark)
* **Chi tiết:** Phát hiện mưu đồ nuốt chửng bản thân của Quỷ Dục Vọng sau khi diệt xong 6 đại tội, cô thầy cúng quyết định "hóa quỷ" hoàn toàn. Cô quay sang tiêu diệt luôn Quỷ Dục Vọng, cướp đoạt ngai vàng và trở thành **Chúa Quỷ tối cao duy nhất** cai trị quỷ giới với quyền năng vô hạn.
* **Điều kiện:** Điểm `sanity` ở mức khá, người chơi chọn rẽ nhánh chiến đấu với Quỷ Dục Vọng (Boss ẩn thứ 7).

### 👼 True Ending: "Thánh Nữ U Buồn" (Tragic Saint Ending - Bittersweet)
* **Chi tiết:** Giữ vững đức tin thanh khiết. Trước trận chiến cuối, cô hy sinh toàn bộ thần lực để cứu linh hồn người bạn. Linh hồn cậu được giải thoát, nhưng thể xác cậu đã qua đời trước đó. Cô được thần linh phong làm Thánh Nữ, rời khỏi quỷ giới và trở về thế gian để lặng lẽ viếng mộ người bạn thuở nhỏ trong u buồn bi tráng.
* **Điều kiện:** `sanity` ở mức cao (>80%), hoàn thành chuỗi sự kiện chuộc tội ẩn và chọn hy sinh bản thân.

---

## 4. Cơ Chế New Game + (NG+): Pregnancy & Parasite

Để giữ cho nhịp độ chơi lần đầu cực kỳ mượt mà, tốc độ cao (đúng chất Metroidvania), các yếu tố H-18 nặng đô như **Mang thai (Pregnancy)** và **Ký sinh (Parasite)** sẽ được kích hoạt riêng ở chế độ **New Game +**:

### A. Cơ chế Ký Sinh (Parasite Mode)
* **Cộng sinh quỷ dị:** Người chơi bị nhiễm một loại ký sinh trùng xúc tu quỷ.
* **Gameplay thay đổi:** 
  * Xúc tu ký sinh sẽ tự động phóng ra tấn công quái vật xung quanh trong lúc bạn combo cận chiến (tăng mạnh sát thương).
  * **Cái giá phải trả:** Ký sinh trùng liên tục **rút máu (HP drain)** của bạn theo thời gian. Bạn bắt buộc phải duy trì combo chiến đấu liên tục để "cho nó ăn", nếu dừng lại quá lâu, nó sẽ nuốt chửng lượng máu còn lại của bạn.

### B. Cơ chế Mang Thai (Pregnancy Mode)
* **Gánh nặng vương quyền:** Thụ thai bởi quỷ năng sau khi thất bại hoặc chọn giao kèo đặc biệt.
* **Gameplay thay đổi:**
  * **Trọng lực vật lý nặng nề:** Tốc độ chạy của nhân vật giảm, khoảng cách Lướt (Dash) ngắn hơn, nhảy đầm tay hơn do cơ thể mang thai nặng nề (ảnh hưởng trực tiếp từ cơ chế vật lý platformer).
  * **Bùng nổ quỷ pháp:** Lượng Mana tối đa tăng vọt, sát thương từ các phép thuật Shaman và quỷ lực tăng gấp đôi.
  * **Giới hạn hòm đồ:** Phân thai quỷ chiếm dụng một phần không gian lưu trữ vật phẩm trong chiếc Balo Trọng Lực, đòi hỏi khả năng sắp xếp diện tích khéo léo hơn.

---

## 5. Lộ Trình Triển Khai Cho Mẫu Thử (Prototype Steps)

1. **Giai đoạn 1 (Đã xong):** Core gameplay di chuyển (Walk, Jump, Dash, Climb, 3-hit combo, QTE, và hệ thống 2D Lighting mượt mà).
2. **Giai đoạn 2 (Tiếp theo):**
   * Lập trình biến số ẩn `sanity_points` liên thông với sát thương nhân vật và QTE/H-scene.
   * Xây dựng màn chơi đầu tiên đại diện cho Cựu Thần Phẫn Nộ (Wrath) với không khí tàn tích rêu phong u sầu và 1 Boss Wrath có AI xả chiêu phản xạ di chuyển.
