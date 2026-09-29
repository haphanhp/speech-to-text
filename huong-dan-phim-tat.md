---
title: Hướng dẫn phím tắt và tự động copy
created: 2026-09-30
tags: [speech-to-text, huong-dan, autohotkey]
---

### Chức năng mới

Bấm một phím tắt là mở app, nói, dừng, chữ tự vào clipboard và bạn được đưa về đúng cửa sổ đang làm việc để dán. Không cần chuột, không cần nhìn.

**Chuỗi thao tác**

1. `Ctrl+Alt+Z` (ở bất kỳ cửa sổ nào): mở app "Nói ra chữ" nếu chưa chạy, hoặc đưa lên trước nếu đang chạy.
2. `Space`: bắt đầu nói.
3. `Space` lần nữa: dừng. App tự copy ngay khi engine nhận diện kết thúc.
4. Nút Copy đổi thành **✓ Copied** (dấu tick động) để bạn biết đã copy.
5. Script đưa bạn về cửa sổ trước đó, bấm `Ctrl+V` để dán.

### Phần nào dùng cho ai

| Phần | Ai dùng được | Cần gì |
|---|---|---|
| `Space` bắt đầu/dừng, tự copy, nút Copied | Mọi người dùng app | Chỉ cần cửa sổ app đang được focus |
| `Ctrl+Alt+Z` toàn cục, tự mở app, tự quay về cửa sổ cũ | Chỉ máy của bạn | AutoHotkey v2 |

Trang web không thể nghe phím khi bạn đang ở cửa sổ khác. Đó là lý do phím tắt toàn cục cần AutoHotkey bên ngoài.

### Cài phím tắt toàn cục (AutoHotkey v2)

1. Mở file `windows/noi-ra-chu.ahk` trong repo.
2. Chép từ dòng `; ===== Nói ra chữ` đến hết file, dán vào **cuối** script AutoHotkey v2 đang chạy cùng Windows của bạn (ví dụ `shortcuttype.ahk`). Hoặc chạy nguyên file `.ahk` này như một script riêng.
3. Nhấp phải biểu tượng H ở khay hệ thống, chọn **Reload Script**.

**Cấu hình trong khối script (đầu class `NoiRaChu`)**

| Biến | Ý nghĩa | Giá trị hiện tại |
|---|---|---|
| `Title` | Tiêu đề cửa sổ + trình duyệt cần khớp | `"Nói ra chữ ahk_exe chrome.exe"` |
| `Url` | Địa chỉ mở app khi chưa chạy | `https://speech-to-text-iota-black.vercel.app/` |
| `Browser` | Trình duyệt dùng để mở app | `chrome.exe` |
| `Restore` | Xong việc thì quay về cửa sổ trước đó | `true` |
| `TimeoutMs` | Bỏ theo dõi nếu quá lâu không dùng | `120000` |

Dùng Edge thì đổi `Title` thành `... ahk_exe msedge.exe` và `Browser` thành `msedge.exe`.

### Cách hoạt động

- Script tìm cửa sổ có tiêu đề chứa "Nói ra chữ" **và** thuộc trình duyệt chỉ định. Nếu không thêm điều kiện trình duyệt, nó nhận nhầm cửa sổ Obsidian đang mở note cùng tên.
- App đổi tiêu đề cửa sổ theo trạng thái: `● Đang nghe`, `… Đang copy`, `✓ Đã copy`, `⚠ Chưa copy`. Script đọc tiêu đề đó để biết khi nào xong, nên quay về cửa sổ cũ đúng lúc copy xong chứ không chờ số giây cố định.
- Copy lỗi (`⚠ Chưa copy`) thì script ở lại cửa sổ app để bạn bấm nút Copy tay.
- Nếu engine không báo kết thúc, app vẫn tự copy sau tối đa 1,5 giây.

### Xử lý sự cố

| Hiện tượng | Nguyên nhân | Cách xử lý |
|---|---|---|
| Bấm phím ra khung "Start typing..." | `Alt+Space` trùng phím của PowerToys Run | Đã dùng `Ctrl+Alt+Z` thay thế; hoặc đổi phím của PowerToys Run |
| Mở nhầm Obsidian | Tiêu đề note chứa "Nói ra chữ" | Thêm `ahk_exe chrome.exe` vào `Title` (đã có sẵn) |
| Không phản hồi khi bấm `Ctrl+Alt+Z` | Bàn phím coi `Ctrl+Alt` là AltGr, hoặc chưa Reload Script | Reload Script; nếu vẫn không được thì đổi tổ hợp khác |
| Không mở được app | `Url` hoặc `Browser` sai | Kiểm tra hai biến này |
| "Chưa copy" | Trình duyệt chặn ghi clipboard khi cửa sổ mất focus | Bấm nút Copy tay; giữ cửa sổ app focus trong lúc dừng |
| Space không nói/dừng | Cửa sổ app chưa được focus | Bấm `Ctrl+Alt+Z` để đưa app lên trước |

### Giới hạn đã biết

- Script AutoHotkey chỉ chạy trên Windows với AutoHotkey v2.
- Tự copy khi không có thao tác bấm phụ thuộc trình duyệt cho phép ghi clipboard lúc cửa sổ app đang focus.
- Cửa sổ mở bằng `--app` có thể hiện thêm một biểu tượng tạm trên taskbar, tách với biểu tượng PWA đã ghim.
