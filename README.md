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
Text nhận được tự copy vào clipboard khi dừng nói (navigator.clipboard.writeText, có fallback execCommand('copy') nếu trình duyệt chặn).
