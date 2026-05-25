# Cấu hình Môi trường Phát triển (Development Environment)

Tệp này ghi lại các thông tin cấu hình quan trọng của dự án để sử dụng cho các đợt thực thi kế tiếp, tránh việc tìm kiếm đường dẫn hoặc chạy các lệnh kiểm tra không cần thiết.

## 1. Thông tin Git
* **Đường dẫn Git executable (Windows):** `C:\Program Files\Git\cmd\git.exe`
* **GitHub Repository:** `https://github.com/hikarirainbow/New-Project.git`
* **Nhánh chính (Main Branch):** `main`
* **Cấu hình Local User:**
  * `user.name`: `hikarirainbow`
  * `user.email`: `hikarirainbow@users.noreply.github.com`

### Các lệnh Git nhanh trong PowerShell:
* Kiểm tra trạng thái:
  ```powershell
  & "C:\Program Files\Git\cmd\git.exe" status
  ```
* Commit và Push nhanh:
  ```powershell
  & "C:\Program Files\Git\cmd\git.exe" add .
  & "C:\Program Files\Git\cmd\git.exe" commit -m "Your commit message"
  & "C:\Program Files\Git\cmd\git.exe" push
  ```
* Kéo code mới nhất:
  ```powershell
  & "C:\Program Files\Git\cmd\git.exe" pull origin main
  ```

---

## 2. Cấu hình Dự án Godot
* **Phiên bản engine tương thích:** Godot 4.6 (Forward Plus)
* **Trình render trên Windows:** Direct3D 12 (`d3d12`)
* **Công cụ vật lý 3D (3D Physics Engine):** Jolt Physics
* **Cảnh chính (Main Scene):** `node_2d.tscn` (`uid://4pqund3nukl7`)

### Cấu trúc thư mục:
* `node_2d.tscn`: Cảnh 2D chính.
* `node_2d.gd`: Tệp mã nguồn của Node2D (trống).
* `project.godot`: Tệp cấu hình dự án của Godot.
* `.gitignore`: Đã cấu hình bỏ qua thư mục cache `.godot/` và thư mục build `/android/`.
