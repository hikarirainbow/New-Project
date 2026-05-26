# LUSTGOD — THE GOTHIC HYBRID ART PIPELINE
*(Quy Trình Sản Xuất Mỹ Thuật Lai 3D-to-AI-2D — Tầm Nhìn Định Hướng Mới)*

Tài liệu này ghi lại định hướng phát triển mỹ thuật mới của dự án **Lustgod**, chính thức chuyển dịch từ đồ họa điểm ảnh (Pixel Art) truyền thống sang **đồ họa 2D độ phân giải cao phong cách Gothic/Semi-realism** bằng cách kết hợp sức mạnh dựng hình 3D (Blender) và trí tuệ nhân tạo (AI Synthesis).

---

## 1. Tầm Nhìn Nghệ Thuật (The Artistic Vision)

* **Loại bỏ phong cách Pixel Art:** Tránh cảm giác hạn chế về chi tiết trong các phân cảnh H-scenes (như *Sinisistar*).
* **Hướng tới phong cách Thornsin-like:** Đạt tới chất lượng vẽ tay đỉnh cao, lai giữa siêu thực (semi-realism) và hội họa kỹ thuật số (digital painting). Tông màu chủ đạo u tối, tương phản cao, đổ bóng mịn màng và khắc họa rõ nét chi tiết biểu cảm, da thịt, vải vóc trong Quỷ Giới.
* **Mượt mà & Chi tiết:** Sử dụng chuyển động mượt mà của 3D làm khung xương, kết phủ lớp da mỹ thuật 2D vẽ tay của AI.

---

## 2. Quy Trình Sản Xuất Lai (The Hybrid Synthesis Pipeline)

Quy trình sản xuất asset nhân vật và H-scene được chia làm 4 giai đoạn khép kín:

```
+------------------+     +------------------+     +------------------+     +------------------+
|   3D Drafting    |     |    Viewport      |     |   AI Synthesis   |     |      Godot       |
|    (Blender)     | ➔   |    Rendering     | ➔   |  (Flux+CN+LoRA)  | ➔   |   Integration    |
| Rig & Animation  |     | Line, Depth, Pose|     | Style & Texture  |     | VRAM WebP, Linear|
+------------------+     +------------------+     +------------------+     +------------------+
```

### Bước 1: Phác Thảo & Chuyển Động 3D (3D Drafting - Blender)
* **Dựng Model Thô (Blockout):** Tạo hình khối nhân vật nữ chính và quái vật với tỷ lệ giải phẫu học (anatomy) chuẩn xác.
* **Rigging & Keyframing:** Thiết lập xương và tạo chuyển động cho các hành động (Idle, Run, Jump, Attack, Grabbed, H-scenes).
* **Lợi ích:** Đảm bảo phối cảnh (perspective), góc camera và tương tác va chạm giữa các nhân vật chính xác tuyệt đối mà không cần vẽ tay từng khung hình từ đầu.

### Bước 2: Trích Xuất Dữ Liệu Dẫn Hướng (Viewport Rendering)
* Render từ khung hình 3D ra các bản đồ dẫn hướng (Guidance Maps) để cấp cho AI:
  * **ControlNet Depth Map:** Bản đồ độ sâu để giữ nguyên hình khối 3D.
  * **ControlNet Canny/Lineart:** Bản đồ nét vẽ biên để giữ nguyên chi tiết ranh giới của nhân vật.
  * **OpenPose Map:** Bản đồ tư thế khớp xương (nếu cần).

### Bước 3: Tổng Hợp Mỹ Thuật Hội Họa (AI Style Synthesis)
* **Flux làm mô hình nền tảng:** Tận dụng khả năng hiểu prompt và cấu trúc giải phẫu cực tốt của Flux.
* **ControlNet kiểm soát cấu trúc:** Khóa chặt tư thế và phối cảnh từ Blender render.
* **Gothic LoRA định hình phong cách:** Sử dụng LoRA được train trên phong cách art u ám, gothic, semi-realistic để ép AI đổ bóng mịn, chi tiết da thịt chân thực.
* **Temporal Consistency (Đồng nhất thời gian):** Áp dụng các giải pháp giảm nhấp nháy hình ảnh giữa các frame (flickering) như EbSynth hoặc AnimateDiff workflow.

### Bước 4: Tích Hợp Vào Engine (Godot Integration)
* Xuất chuỗi sprite sheets độ phân giải cao dạng ảnh nén WebP để tối ưu dung lượng VRAM.

---

## 3. Điều Chỉnh Kỹ Thuật Trong Godot (Godot Engine Adapters)

Khi chuyển dịch từ Pixel Art sang đồ họa HD Hybrid, dự án cần thay đổi các thông số kỹ thuật hiển thị để đón đầu asset mới:

| Tính năng | Cấu hình Pixel Art cũ | Cấu hình HD Hybrid mới |
| :--- | :--- | :--- |
| **Viewport Resolution** | `640x360` (Thấp) | `1280x720` (HD) hoặc `1920x1080` (FHD) |
| **Window Override** | `1280x720` | Tắt hoặc giữ nguyên tỉ lệ gốc tương ứng |
| **Texture Filter** | `Nearest` (Sắc cạnh răng cưa) | `Linear` (Lọc mượt mà, chống vỡ nét vẽ tay) |
| **Texture Compression** | Lossless (PNG) | VRAM Compressed / WebP (Tối ưu tải VRAM) |
| **Stretch Mode** | `canvas_items` (Nearest stretch) | `canvas_items` (Linear stretch) |

---

## 4. Kế Hoạch Thử Nghiệm (Pilot Test Plan)

Để kiểm chứng tính khả thi của quy trình trước khi áp dụng hàng loạt:
1. **Dựng 1 dáng Idle thô:** Tạo chuyển động thở/đứng yên của nhân vật nữ chính trong Blender (khoảng 10-15 frames).
2. **AI Render Test:** Chạy chuỗi frame qua quy trình *Flux + ControlNet (Depth) + Gothic LoRA* để kiểm tra độ ổn định chi tiết (quần áo, tóc tai có bị biến dạng nhiều giữa các frame hay không).
3. **Godot Load Test:** Import vào màn chơi thử nghiệm, đổi cấu hình Viewport sang HD và chạy thử để kiểm định tốc độ khung hình và cảm quan mỹ thuật thực tế.
