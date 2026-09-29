### Tool này là gì
Một trang web rất nhỏ (1 file HTML + JS, không backend, không server riêng), cài được thành app trên Windows qua Chrome (PWA). Bấm nút micro, nói tiếng Việt, chữ hiện ra realtime và tự động copy vào clipboard — dán (Ctrl+V) vào bất cứ đâu: Claude, Word, ô chat khác.
Ghim trên task bar thành tiện ích nhỏ để có văn bản bằng giọng nói thay cho việc gõ tay.
Không dùng Whisper, không dùng model AI nào cài trên máy. Dùng thẳng công nghệ nhận diện giọng nói có sẵn trong trình duyệt (Web Speech API / webkitSpeechRecognition), phía sau chính là engine của Google — nên nhận tiếng Việt tốt, và miễn phí, không giới hạn phút, không cần API key.

### Vì sao làm cái này thay vì cài jarvis/Ollama
Xuất phát từ việc tìm hiểu cài trợ lý giọng nói kiểu isair/jarvis (chạy Whisper + LLM local). Máy X99 hiện tại có GPU RX 550 4GB (kiến trúc Polaris) không được ROCm hỗ trợ, nên mọi thứ chạy AI local đều rơi về CPU — đúng vấn đề đã ghi nhận với Ollama (chỉ 3-5 token/giây, không dùng nổi). Whisper local trên máy này nhiều khả năng cũng chậm tương tự.

Giải pháp: bỏ hẳn việc chạy AI cục bộ cho khâu nghe, dùng thẳng engine nhận diện giọng nói của Google chạy trên cloud (qua trình duyệt) — máy yếu không còn là vấn đề vì không phải tính toán gì nặng ở máy mình.

Xem chi tiết cấu hình máy và lý do GPU là nút thắt: xem file cấu hình máy trong 06.he-thong-pc (mục "09 nang cap phan cung").

### Cách hoạt động (kỹ thuật)
1 file index.html dùng SpeechRecognition/webkitSpeechRecognition, lang = 'vi-VN', continuous = true, interimResults = true.
Có manifest.json + icon để cài thành PWA (app riêng, ghim được taskbar).
Có sw.js (service worker tối giản, không cache gì) — chỉ để Chrome chấp nhận cho cài đặt PWA.
Cửa sổ tự co nhỏ (320×480) và tự ghim góc dưới-phải màn hình mỗi lần mở (script resizeTo/moveTo, chỉ chạy khi mở ở chế độ app đã cài).
Text nhận được tự copy vào clipboard ngay khi engine nhận diện kết thúc sau khi bấm dừng (thường dưới 1 giây) (navigator.clipboard.writeText, có fallback execCommand('copy') nếu trình duyệt chặn). Nút Copy đổi thành "Copied" kèm dấu tick động trong 2 giây khi copy thành công.

### Cách cài vào máy (1 lần)

1. Mở link deploy bằng Chrome.
2. Bấm menu ⋮ góc phải → "Cài đặt Nói ra chữ..." (Install).
3. Chuột phải icon app vừa mở dưới taskbar → "Ghim vào Taskbar".
4. Lần đầu dùng, Chrome sẽ xin quyền micro — cho phép.
5. Script đã thu nhỏ cửa sổ lại mỗi lần mở, không mất công chỉnh sửa nhiều lần, không gián đoạn công việc, giảm ma sát UX.

### Minh họa 
- _ghim trên thanh taskbar tiện sử dụng_
- _Miễn phí._
- _Nhận tiếng Việt tốt._
- _Bổ trợ cho tăng tốc vibe-code._
- _Không cần cài MCP._
- _Không gây nặng máy._

<img src="https://raw.githubusercontent.com/tudotaichinh/image-auto/Obsidian/Obsidian20260928164815.png" width="400">

<img src="https://raw.githubusercontent.com/tudotaichinh/image-auto/Obsidian/Obsidian20260928164900.png" width="400">

### Phím tắt

- Trong cửa sổ app: `Space` bắt đầu nói, `Space` lần nữa dừng nói (app tự copy ngay khi engine kết thúc).
- Phím tắt toàn cục (tuỳ chọn, chỉ cho máy bạn): chạy `windows/noi-ra-chu.ahk` bằng AutoHotkey v2. `Alt+Space` ở bất kỳ cửa sổ nào: nếu app đang chạy thì đưa lên trước, nếu chưa chạy thì tự mở bằng địa chỉ web (điền `appUrl` trong file). Sau đó `Space` để nói, `Space` để dừng. Khi app báo "Đã copy", script đưa bạn về cửa sổ trước đó (tắt bằng `restorePrevWindow := false`).
- App đổi tiêu đề cửa sổ theo trạng thái (đang nghe, đang copy, đã copy, chưa copy) để script biết khi nào xong.
