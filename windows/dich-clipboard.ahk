; Phím tắt toàn cục: dịch nhanh nội dung clipboard sang tiếng Việt (AutoHotkey v2), chỉ dành cho máy của bạn.
; Có thể chạy riêng file này, hoặc dán từ dòng "===== Dịch clipboard" xuống cuối vào script AHK v2 chính.
; Không mở cửa sổ/app nào — gọi thẳng API dịch miễn phí của Google (endpoint không cần API key,
; cùng cơ chế các công cụ mã nguồn mở như googletrans/translate-shell vẫn dùng), nên nhẹ và tức thời.

#Requires AutoHotkey v2.0
#SingleInstance Force

; ===== Dịch clipboard: Ctrl+Alt+D = lấy chữ đang có trong clipboard, dịch sang tiếng Việt, tự copy kết quả =====
^!d::DichClipboard()

DichClipboard() {
    text := Trim(A_Clipboard)
    if (text = "") {
        ToolTip "Clipboard trống, chưa copy gì để dịch"
        SetTimer () => ToolTip(), -1500
        return
    }
    ToolTip "Đang dịch..."
    try {
        translated := GoogleTranslateFree(text, "vi")
    } catch as e {
        ToolTip "Lỗi dịch: " e.Message
        SetTimer () => ToolTip(), -3000
        return
    }
    if (translated = "") {
        ToolTip "Không dịch được (server không trả kết quả)"
        SetTimer () => ToolTip(), -2500
        return
    }
    A_Clipboard := translated
    ToolTip "✓ Đã dịch & copy — Ctrl+V để dán"
    SetTimer () => ToolTip(), -1800
}

; Gọi endpoint dịch miễn phí, không cần API key, của Google (client=gtx).
; targetLang: mã ngôn ngữ đích (vd "vi"). sourceLang: "auto" để tự nhận diện.
GoogleTranslateFree(text, targetLang := "vi", sourceLang := "auto") {
    url := "https://translate.googleapis.com/translate_a/single"
        . "?client=gtx&sl=" sourceLang "&tl=" targetLang "&dt=t&q=" UrlEncodeUtf8(text)
    req := ComObject("WinHttp.WinHttpRequest.5.1")
    req.Open("GET", url, false)
    req.SetRequestHeader("User-Agent", "Mozilla/5.0")
    req.Send()
    if (req.Status != 200)
        throw Error("HTTP " req.Status)
    resp := req.ResponseText

    ; Response gốc là JSON lồng nhiều tầng: [[[ "bản dịch","gốc",null,null,...], ...], null, "en", ...]
    ; Phần ta cần CHỈ nằm trong mảng đầu tiên (result[0]) — các phần sau (ngôn ngữ phát hiện,
    ; từ điển, gợi ý thay thế...) không phải bản dịch nên phải cắt bỏ, nếu không sẽ bị dính rác vào kết quả.
    seg0 := ExtractSegment0(resp)

    out := ""
    pos := 1
    while (pos := RegExMatch(seg0, '\[\s*"((?:\\.|[^"\\])*)"\s*,\s*"(?:\\.|[^"\\])*"', &m, pos)) {
        chunk := m[1]
        chunk := StrReplace(chunk, "\n", "`n")
        chunk := StrReplace(chunk, '\"', '"')
        chunk := StrReplace(chunk, "\\", "\")
        out .= chunk
        pos += StrLen(m[0])
    }
    return out
}

; Trích đúng mảng result[0] (danh sách các đoạn đã dịch) bằng cách đếm độ sâu ngoặc vuông,
; có bỏ qua ngoặc nằm bên trong chuỗi "..." (để không vỡ khi bản dịch chứa ký tự [ ] thật).
ExtractSegment0(resp) {
    depth := 0
    startPos := 0
    inStr := false
    n := StrLen(resp)
    i := 1
    while (i <= n) {
        ch := SubStr(resp, i, 1)
        if (inStr) {
            if (ch = "\")
                i += 1
            else if (ch = '"')
                inStr := false
        } else {
            if (ch = '"')
                inStr := true
            else if (ch = "[") {
                depth++
                if (depth = 2 && startPos = 0)
                    startPos := i
            } else if (ch = "]") {
                if (depth = 2 && startPos != 0)
                    return SubStr(resp, startPos, i - startPos + 1)
                depth--
            }
        }
        i++
    }
    return resp
}

; Percent-encode UTF-8 đúng chuẩn (AHK v2 string -> bytes UTF-8 -> %XX).
UrlEncodeUtf8(str) {
    static Safe := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~"
    needed := StrPut(str, "UTF-8") - 1          ; số byte UTF-8, không tính null terminator
    buf := Buffer(needed)
    StrPut(str, buf, "UTF-8")
    out := ""
    Loop needed {
        b := NumGet(buf, A_Index - 1, "UChar")
        ch := Chr(b)
        if InStr(Safe, ch) && b < 128
            out .= ch
        else
            out .= Format("%{:02X}", b)
    }
    return out
}
