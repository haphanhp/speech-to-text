; Phím tắt toàn cục: dịch nhanh nội dung clipboard sang tiếng Việt (AutoHotkey v2), chỉ dành cho máy của bạn.
; Có thể chạy riêng file này, hoặc dán từ dòng "===== Dịch clipboard" xuống cuối vào script AHK v2 chính.
; Không mở cửa sổ/app nào — gọi thẳng API dịch miễn phí: Google trước, MyMemory dự phòng nếu Google
; lỗi/rỗng (429, timeout...), để không phụ thuộc một bên duy nhất. Cả hai đều không cần API key.
; Thêm MyMemory làm dự phòng ngày 31/10/2026.
; Thêm Ctrl+Alt+D (cửa sổ nhỏ chọn ngôn ngữ nguồn/đích, kiểu mini Google Dịch) ngày 31/10/2026,
; dùng khi không dịch sang tiếng Việt (Trung↔Anh, Anh↔Pháp...).

#Requires AutoHotkey v2.0
#SingleInstance Force

; ===== Dịch clipboard: Ctrl+Alt+V = lấy chữ đang có trong clipboard, dịch sang tiếng Việt, tự copy kết quả =====
; (Đổi từ Ctrl+Alt+D sang Ctrl+Alt+V ngày 31/10/2026 vì D trùng phím quay màn hình trên máy chính.)
; Ctrl+Alt+D (dùng lại ngày 31/10/2026) = mở cửa sổ nhỏ chọn ngôn ngữ nguồn/đích (như Google Dịch).
^!v::DichClipboard()
^!d::ShowTranslatePicker()

DichClipboard() {
    text := Trim(A_Clipboard)
    if (text = "") {
        ToolTip "Clipboard trống, chưa copy gì để dịch"
        SetTimer () => ToolTip(), -1500
        return
    }
    ToolTip "Đang dịch..."

    ; Thử Google trước, lỗi (429, timeout, mạng...) hoặc rỗng thì tự rớt sang MyMemory dự phòng,
    ; để không phụ thuộc một bên duy nhất.
    translated := ""
    err1 := "", err2 := ""
    try {
        translated := GoogleTranslateFree(text, "vi")
    } catch as e {
        err1 := e.Message
    }
    if (translated = "") {
        try {
            translated := MyMemoryTranslateFree(text, "vi")
        } catch as e {
            err2 := e.Message
        }
    }

    if (translated = "") {
        msg := "Không dịch được (cả 2 nguồn đều lỗi)"
        if (err1 != "" || err2 != "")
            msg .= "`nGoogle: " (err1 = "" ? "trống" : err1) " | MyMemory: " (err2 = "" ? "trống" : err2)
        ToolTip msg
        SetTimer () => ToolTip(), -3500
        return
    }
    A_Clipboard := translated
    ToolTip "✓ Đã dịch & copy — Ctrl+V để dán"
    SetTimer () => ToolTip(), -1800
}

; Ngưỡng an toàn độ dài URL sau khi percent-encode — vượt mức này MyMemory từng trả "414 URI Too Long"
; (xảy ra khi clipboard lỡ chứa nguyên 1 file dài thay vì đoạn text ngắn định dịch).
TRANSLATE_MAX_ENCODED_LEN := 1800

; ResponseText của WinHttpRequest tự đoán bảng mã từ header Content-Type — khi server không khai
; rõ charset=utf-8 (hay gặp ở API JSON), nó đoán sai theo bảng mã mặc định của Windows, làm hỏng
; MỌI ký tự ngoài ASCII (tiếng Việt, Pháp, Trung...), trong khi tiếng Anh (toàn ASCII) thì không lộ
; lỗi vì ASCII giống nhau ở mọi bảng mã — đây là nguyên nhân thật của các lỗi hiển thị ký tự gặp
; phải. Khắc phục: đọc byte thô (ResponseBody) rồi tự ép giải mã UTF-8 qua ADODB.Stream.
ReadUtf8Response(req) {
    stream := ComObject("ADODB.Stream")
    stream.Type := 1          ; adTypeBinary
    stream.Open()
    stream.Write(req.ResponseBody)
    stream.Position := 0
    stream.Type := 2          ; adTypeText
    stream.Charset := "utf-8"
    text := stream.ReadText()
    stream.Close()
    return text
}

; ===== Nguồn chính: Google (miễn phí, không cần API key, tự nhận diện ngôn ngữ nguồn) =====
; targetLang: mã ngôn ngữ đích (vd "vi"). sourceLang: "auto" để tự nhận diện.
GoogleTranslateFree(text, targetLang := "vi", sourceLang := "auto") {
    global TRANSLATE_MAX_ENCODED_LEN
    encoded := UrlEncodeUtf8(text)
    if (StrLen(encoded) > TRANSLATE_MAX_ENCODED_LEN)
        throw Error("Văn bản quá dài (" StrLen(text) " ký tự) để dịch qua API miễn phí — dịch từng đoạn ngắn hơn.")
    url := "https://translate.googleapis.com/translate_a/single"
        . "?client=gtx&sl=" sourceLang "&tl=" targetLang "&dt=t&q=" encoded
    req := ComObject("WinHttp.WinHttpRequest.5.1")
    req.Open("GET", url, false)
    req.SetRequestHeader("User-Agent", "Mozilla/5.0")
    req.Send()
    if (req.Status != 200)
        throw Error("HTTP " req.Status)
    resp := ReadUtf8Response(req)

    ; Response gốc là JSON lồng nhiều tầng: [[[ "bản dịch","gốc",null,null,...], ...], null, "en", ...]
    ; Phần ta cần CHỈ nằm trong mảng đầu tiên (result[0]) — các phần sau (ngôn ngữ phát hiện,
    ; từ điển, gợi ý thay thế...) không phải bản dịch nên phải cắt bỏ, nếu không sẽ bị dính rác vào kết quả.
    seg0 := ExtractSegment0(resp)

    out := ""
    pos := 1
    while (pos := RegExMatch(seg0, '\[\s*"((?:\\.|[^"\\])*)"\s*,\s*"(?:\\.|[^"\\])*"', &m, pos)) {
        out .= DecodeJsonString(m[1])
        pos += StrLen(m[0])
    }
    return out
}

; ===== Nguồn dự phòng: MyMemory (miễn phí, không cần API key, nhưng giới hạn ~5000 từ/ngày
; theo IP khi dùng ẩn danh, và không tự nhận diện ngôn ngữ nguồn như Google — mặc định "en"). =====
MyMemoryTranslateFree(text, targetLang := "vi", sourceLang := "en") {
    global TRANSLATE_MAX_ENCODED_LEN
    ; MyMemory không hỗ trợ dịch 1 ngôn ngữ sang chính nó — thay vì gọi API rồi nhận về lỗi
    ; giả dạng kết quả hợp lệ (xem ghi chú response bên dưới), chặn luôn từ đầu.
    if (sourceLang = targetLang)
        throw Error("Ngôn ngữ nguồn và đích trùng nhau (" targetLang ")")
    encoded := UrlEncodeUtf8(text)
    if (StrLen(encoded) > TRANSLATE_MAX_ENCODED_LEN)
        throw Error("Văn bản quá dài (" StrLen(text) " ký tự) để dịch qua API miễn phí — dịch từng đoạn ngắn hơn.")
    url := "https://api.mymemory.translated.net/get"
        . "?q=" encoded "&langpair=" sourceLang "|" targetLang
    req := ComObject("WinHttp.WinHttpRequest.5.1")
    req.Open("GET", url, false)
    req.SetRequestHeader("User-Agent", "Mozilla/5.0")
    req.Send()
    if (req.Status != 200)
        throw Error("HTTP " req.Status)
    resp := ReadUtf8Response(req)

    ; MyMemory hay trả HTTP 200 ngay cả khi lỗi (vd chọn trùng ngôn ngữ, hết quota) — lỗi thật nằm
    ; trong "responseStatus" của JSON (không phải HTTP status), nên phải tự kiểm thêm, nếu không
    ; code sẽ tưởng chuỗi lỗi đó ("PLEASE SELECT TWO DISTINCT LANGUAGES"...) là bản dịch thật.
    if RegExMatch(resp, '"responseStatus"\s*:\s*"?(\d+)"?', &rs) && rs[1] != "200" {
        ; Khi lỗi (vd hết quota ngày), translatedText thường chứa luôn thông báo người đọc được,
        ; kiểu "...NEXT AVAILABLE IN 09:12:34 DATETIME..." — trích ra cho rõ thay vì chỉ ghi số status.
        detail := ""
        if RegExMatch(resp, '"translatedText"\s*:\s*"((?:\\.|[^"\\])*)"', &dm)
            detail := DecodeJsonString(dm[1])
        throw Error("MyMemory lỗi (status " rs[1] ")" (detail != "" ? ": " detail : ""))
    }

    ; Response dạng {"responseData":{"translatedText":"...",...}, "responseStatus":200, ...}
    if !RegExMatch(resp, '"translatedText"\s*:\s*"((?:\\.|[^"\\])*)"', &m)
        throw Error("Không tìm thấy translatedText trong response")
    return DecodeJsonString(m[1])
}

; Giải mã escape JSON đúng chuẩn trong 1 lượt quét: \uXXXX (kể cả surrogate pair cho ký tự ngoài
; BMP như 1 số emoji), \n, \t, \", \/, \\. Trước đây dùng StrReplace rời rạc nên bỏ sót \uXXXX —
; MyMemory hay trả tiếng Việt dạng "b\u1ea1n" thay vì "bạn", dán ra bị dính nguyên chuỗi escape.
DecodeJsonString(s) {
    out := ""
    n := StrLen(s)
    i := 1
    while (i <= n) {
        ch := SubStr(s, i, 1)
        if (ch = "\" && i < n) {
            nx := SubStr(s, i + 1, 1)
            if (nx = "u" && i + 5 <= n) {
                code := Integer("0x" SubStr(s, i + 2, 4))
                if (code >= 0xD800 && code <= 0xDBFF && SubStr(s, i + 6, 2) = "\u" && i + 11 <= n) {
                    code2 := Integer("0x" SubStr(s, i + 8, 4))
                    if (code2 >= 0xDC00 && code2 <= 0xDFFF) {
                        out .= Chr(0x10000 + (code - 0xD800) * 0x400 + (code2 - 0xDC00))
                        i += 12
                        continue
                    }
                }
                out .= Chr(code)
                i += 6
                continue
            } else if (nx = "n") {
                out .= "`n", i += 2
                continue
            } else if (nx = "t") {
                out .= "`t", i += 2
                continue
            } else if (nx = '"' || nx = "\" || nx = "/") {
                out .= nx, i += 2
                continue
            }
        }
        out .= ch
        i += 1
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

; ===== Giao diện nhỏ chọn ngôn ngữ (Ctrl+Alt+D) — kiểu mini Google Dịch =====
; "Tự động nhận diện" chỉ dùng được cho ô NGUỒN (Google hỗ trợ, MyMemory dự phòng thì không).
global TP_SrcNames := ["Tự động nhận diện", "Tiếng Việt", "Tiếng Anh", "Tiếng Trung", "Tiếng Pháp"]
global TP_DstNames := ["Tiếng Việt", "Tiếng Anh", "Tiếng Trung", "Tiếng Pháp"]
global TP_LangCodes := Map(
    "Tự động nhận diện", "auto",
    "Tiếng Việt", "vi",
    "Tiếng Anh", "en",
    "Tiếng Trung", "zh-CN",
    "Tiếng Pháp", "fr")

global TP_Gui := 0, TP_DDLFrom := 0, TP_DDLTo := 0, TP_EditSrc := 0, TP_EditResult := 0, TP_Status := 0

ShowTranslatePicker() {
    global TP_Gui, TP_DDLFrom, TP_DDLTo, TP_EditSrc, TP_EditResult, TP_Status, TP_SrcNames, TP_DstNames

    if IsObject(TP_Gui)
        TP_Gui.Destroy()

    TP_Gui := Gui("+AlwaysOnTop", "Dịch nhanh (chọn ngôn ngữ)")
    TP_Gui.SetFont("s10")
    TP_Gui.OnEvent("Close", (*) => TP_Gui.Hide())
    TP_Gui.OnEvent("Escape", (*) => TP_Gui.Hide())

    TP_Gui.Add("Text", "xm y12", "Từ:")
    TP_DDLFrom := TP_Gui.Add("DropDownList", "x45 y8 w190 Choose1", TP_SrcNames)

    TP_Gui.Add("Text", "x250 y12", "Sang:")
    TP_DDLTo := TP_Gui.Add("DropDownList", "x300 y8 w190 Choose1", TP_DstNames)

    TP_EditSrc := TP_Gui.Add("Edit", "xm y40 w480 h100 Multi WantReturn", Trim(A_Clipboard))

    btnDich := TP_Gui.Add("Button", "xm y150 w100 h30 Default", "Dịch")
    btnDich.OnEvent("Click", (*) => DoTranslatePicker())

    btnCopy := TP_Gui.Add("Button", "x110 y150 w100 h30", "Copy kết quả")
    btnCopy.OnEvent("Click", (*) => CopyTranslatePickerResult())

    TP_EditResult := TP_Gui.Add("Edit", "xm y190 w480 h100 Multi ReadOnly")

    TP_Status := TP_Gui.Add("Text", "xm y300 w480", "")

    TP_Gui.Show()
}

DoTranslatePicker() {
    global TP_DDLFrom, TP_DDLTo, TP_EditSrc, TP_EditResult, TP_Status, TP_LangCodes

    text := Trim(TP_EditSrc.Text)
    if (text = "") {
        TP_Status.Text := "Chưa có chữ để dịch"
        return
    }
    srcCode := TP_LangCodes[TP_DDLFrom.Text]
    dstCode := TP_LangCodes[TP_DDLTo.Text]

    ; Chặn sớm nếu đã chọn trùng ngôn ngữ nguồn/đích — không cần gọi API mới biết lỗi.
    if (srcCode != "auto" && srcCode = dstCode) {
        TP_Status.Text := "Ngôn ngữ nguồn và đích giống nhau, chọn lại giúp."
        return
    }

    TP_Status.Text := "Đang dịch..."
    translated := ""
    err1 := "", err2 := ""
    try {
        translated := GoogleTranslateFree(text, dstCode, srcCode)
    } catch as e {
        err1 := e.Message
    }
    if (translated = "") {
        ; MyMemory không hỗ trợ "auto" — nếu nguồn đang để Tự động, đoán tạm 1 ngôn ngữ cụ thể khi
        ; rớt dự phòng, nhưng phải khác ngôn ngữ đích (nếu không MyMemory báo lỗi "chọn 2 ngôn ngữ
        ; khác nhau" — từng xảy ra khi đích là Tiếng Anh và code cũng đoán nguồn là "en").
        fallbackSrc := (srcCode != "auto") ? srcCode : (dstCode = "en" ? "vi" : "en")
        try {
            translated := MyMemoryTranslateFree(text, dstCode, fallbackSrc)
        } catch as e {
            err2 := e.Message
        }
    }

    if (translated = "") {
        TP_Status.Text := "Lỗi: " (err1 != "" ? err1 : "") (err2 != "" ? " | " err2 : "")
        return
    }

    TP_EditResult.Text := translated
    A_Clipboard := translated
    TP_Status.Text := "✓ Đã dịch & copy — Ctrl+V để dán"
}

CopyTranslatePickerResult() {
    global TP_EditResult, TP_Status
    A_Clipboard := TP_EditResult.Text
    TP_Status.Text := "✓ Đã copy"
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
