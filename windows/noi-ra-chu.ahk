; Phím tắt toàn cục cho app "Nói ra chữ" (AutoHotkey v2), chỉ dành cho máy của bạn.
; Có thể chạy riêng file này, hoặc dán từ dòng "===== Nói ra chữ" xuống cuối vào script AHK v2 chính.

#Requires AutoHotkey v2.0
#SingleInstance Force

; ===== Nói ra chữ: Ctrl+Alt+Z = mở/đưa app lên trước; sau đó Space để nói, Space để dừng =====
^!z::NoiRaChu.Focus()

class NoiRaChu {
    ; --- Cấu hình ---
    static Title := "Nói ra chữ ahk_exe chrome.exe"                ; tiêu đề + đúng trình duyệt (đổi cả chrome.exe nếu dùng Edge)
    static Url := "https://speech-to-text-iota-black.vercel.app/"
    static Browser := "chrome.exe"                                 ; hoặc "msedge.exe"
    static Restore := true                                         ; xong việc thì quay về cửa sổ trước đó
    static TimeoutMs := 120000                                     ; bỏ theo dõi nếu quá lâu không dùng
    ; --- Trạng thái nội bộ ---
    static Prev := 0
    static SawListening := false
    static ArmedAt := 0
    static WatchFn := 0

    static Focus() {
        SetTitleMatchMode 2
        cur := WinExist("A")
        appHwnd := WinExist(this.Title)
        if !appHwnd {
            ; Chưa chạy: mở cửa sổ app độc lập bằng địa chỉ web, không cần shortcut.
            Run this.Browser ' --app="' this.Url '"'
            appHwnd := WinWait(this.Title, , 10)
            if !appHwnd {
                ToolTip "Không mở được app (kiểm tra Url và Browser)"
                SetTimer () => ToolTip(), -3000
                return
            }
            Sleep 800                                              ; chờ trang tải để nhận phím Space
        }
        this.Prev := (cur != appHwnd) ? cur : 0
        this.SawListening := false
        this.ArmedAt := A_TickCount
        WinActivate appHwnd
        WinWaitActive appHwnd, , 1
        if this.Restore && this.Prev {
            if !this.WatchFn
                this.WatchFn := ObjBindMethod(this, "Watch")
            SetTimer this.WatchFn, 150
        }
    }

    ; Đọc tiêu đề cửa sổ app để biết khi nào nói xong và copy xong.
    static Watch() {
        SetTitleMatchMode 2
        appHwnd := WinExist(this.Title)
        if !appHwnd || !this.Prev || A_TickCount - this.ArmedAt > this.TimeoutMs {
            SetTimer this.WatchFn, 0
            this.Prev := 0
            return
        }
        title := WinGetTitle(appHwnd)
        if InStr(title, "Đang nghe") {
            this.SawListening := true
            return
        }
        if InStr(title, "Chưa copy") {                             ; copy lỗi: ở lại để bấm nút Copy
            SetTimer this.WatchFn, 0
            this.Prev := 0
            return
        }
        ; "Đã copy", hoặc nghe xong mà không có chữ nào (tiêu đề về lại bình thường)
        if InStr(title, "Đã copy") || (this.SawListening && !InStr(title, "Đang copy")) {
            SetTimer this.WatchFn, 0
            if WinExist("ahk_id " this.Prev)
                WinActivate "ahk_id " this.Prev
            this.Prev := 0
        }
    }
}
