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

### Dịch clipboard nhanh (không mở app)

Công cụ riêng, không liên quan tới app "Nói ra chữ" ở trên — chỉ dùng chung repo này cho gọn. Chạy qua AutoHotkey, không phải trong trang web.

- `Ctrl+Alt+V` ở bất kỳ đâu: copy đoạn text bất kỳ → bấm tổ hợp này → bản dịch **tiếng Việt** tự nằm sẵn trong clipboard, `Ctrl+V` để dán.
- `Ctrl+Alt+D` ở bất kỳ đâu: mở 1 cửa sổ nhỏ kiểu mini Google Dịch — chọn ngôn ngữ nguồn (có "Tự động nhận diện") và ngôn ngữ đích (Việt/Anh/Trung/Pháp), dùng khi không dịch sang tiếng Việt.

Không mở trình duyệt, chạy ngầm, gọi thẳng 2 nguồn dịch miễn phí không cần API key, theo kiểu nguồn chính + dự phòng:
- **Google** (`translate.googleapis.com/translate_a/single`, `client=gtx`) — cùng cơ chế các công cụ mã nguồn mở như `googletrans`/`translate-shell` vẫn dùng, khác với Google Cloud Translation API chính thức phải trả phí.
- **MyMemory** (`api.mymemory.translated.net`) làm dự phòng khi Google lỗi/rỗng (vd bị rate-limit) — hạ tầng khác hẳn Google nên hiếm khi cùng bị chặn một lúc.

- File: `windows/dich-clipboard.ahk` (AutoHotkey v2) — bản dự phòng/tham khảo trong repo, không chạy trực tiếp. Bản đang chạy thật nằm ở script chính trên máy cá nhân (gộp chung với các hotkey khác để đỡ nhiều process AHK).
- Đổi ngôn ngữ đích của `Ctrl+Alt+V`: sửa `"vi"` trong dòng `GoogleTranslateFree(text, "vi")`.
- Đổi phím tắt: sửa `^!v::` / `^!d::` ở đầu file (`^` = Ctrl, `!` = Alt).
- Giới hạn: cả 2 endpoint đều miễn phí/không chính thức, không có SLA — nếu cả 2 cùng bị chặn/hết quota thì cần thêm provider khác (DeepL free key, v.v.).

### Đọc to văn bản (Text-to-Speech)

Nằm ngay trong trang `index.html`, ô "🔊 Đọc to văn bản" phía trên ô "Nói ra chữ" — không phải tool riêng, không cần cài gì thêm, không có hotkey toàn cục.

Dán hoặc gõ văn bản vào ô, chọn ngôn ngữ (Việt / Anh / Trung / Pháp), bấm "▶️ Đọc". Nút "📋 Dán" tự lấy nội dung đang có trong clipboard; nút "⏹" dừng đọc.

**Cơ chế 2 lớp (giống mô hình dịch ở trên: nguồn chính + dự phòng):**
- **Ưu tiên giọng cài sẵn trên Windows** (Web Speech API `speechSynthesis`) — đọc hoàn toàn offline trên máy, miễn phí, không giới hạn, chất lượng tùy giọng SAPI đã cài.
- **Nếu máy chưa có giọng cho ngôn ngữ đã chọn**, tự động rớt sang **Google Translate TTS** (`translate.google.com/translate_tts`, không cần API key) — đọc online qua mạng; văn bản dài tự cắt thành nhiều đoạn ngắn (~180 ký tự/đoạn) rồi phát nối tiếp.

**Cài thêm giọng đọc tiếng Trung/Pháp trên Windows (để đọc offline, không phụ thuộc mạng/Google TTS):**
1. Mở **Settings → Time & Language → Language & region**.
2. Bấm **"Add a language"**, tìm và thêm **"Chinese (Simplified, China)"** và **"French (France)"**.
3. Bấm vào từng ngôn ngữ vừa thêm → mục **"Speech"** → đợi tải xong (ngôn ngữ và giọng đọc Text-to-speech đôi khi là 2 gói tải riêng — kiểm cả hai, đừng tưởng thêm ngôn ngữ xong là có giọng luôn).
4. Kiểm lại tại **Settings → Time & Language → Speech → "Manage voices"** (hoặc mục "Installed voice packages" tương đương) để xác nhận đã có đủ Chinese/French.
5. **Đóng hẳn toàn bộ Chrome** (kiểm cả khay hệ thống, vì Chrome có thể vẫn chạy ngầm) rồi mở lại — Chrome chỉ đọc danh sách giọng SAPI **một lần lúc khởi động tiến trình**, F5 trang không đủ để nhận giọng mới. Nếu vẫn chưa thấy, khởi động lại máy.

Lưu ý chung khi code trang web có cập nhật (push lên GitHub, Vercel tự build lại): **F5 lại cửa sổ "Nói ra chữ" đang mở** để tải code mới — mở app qua `Ctrl+Alt+Z` chỉ đưa cửa sổ cũ lên trước, không tự tải lại trang.

### Phím tắt

Hướng dẫn đầy đủ: [huong-dan-phim-tat.md](huong-dan-phim-tat.md).

- Trong cửa sổ app: `Alt` (bấm rồi thả, không kèm phím khác) bắt đầu nói, `Alt` lần nữa dừng nói (app tự copy ngay khi engine kết thúc). Đổi từ `Space` sang `Alt` ngày 31/10/2026 để `Space` gõ được dấu cách bình thường trong ô "Đọc to văn bản" mới thêm (trước đó `Space` bị bắt toàn cục nên không gõ cách được trong ô đó).
- Phím tắt toàn cục (tuỳ chọn, chỉ cho máy bạn): chạy `windows/noi-ra-chu.ahk` bằng AutoHotkey v2. `Ctrl+Alt+Z` ở bất kỳ cửa sổ nào: nếu app đang chạy thì đưa lên trước, nếu chưa chạy thì tự mở bằng địa chỉ web (điền `appUrl` trong file). Sau đó `Alt` để nói, `Alt` để dừng. Khi app báo "Đã copy", script đưa bạn về cửa sổ trước đó (tắt bằng `restorePrevWindow := false`).
- App đổi tiêu đề cửa sổ theo trạng thái (đang nghe, đang copy, đã copy, chưa copy) để script biết khi nào xong.
