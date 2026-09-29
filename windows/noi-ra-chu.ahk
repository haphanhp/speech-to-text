; Phím tắt toàn cục cho app "Nói ra chữ" (AutoHotkey v2), chỉ dành cho máy của bạn.
;
;   Alt+Space (ở bất kỳ cửa sổ nào):
;     - App đang chạy  -> đưa cửa sổ app lên trước.
;     - App chưa chạy  -> tự mở app rồi đưa lên trước.
;   Sau đó bấm Space để nói, Space lần nữa để dừng (app tự copy).
;   Khi app báo "Đã copy", script đưa bạn về cửa sổ trước đó để dán (tắt bằng restorePrevWindow := false).
;
; Nếu bạn đang dùng AutoHotkey v1 thì báo lại để đổi cú pháp.

#Requires AutoHotkey v2.0
#SingleInstance Force
SetTitleMatchMode 2

appTitle := "Nói ra chữ"          ; trùng với <title> của trang (app còn thêm tiền tố trạng thái)

; --- Cấu hình cách MỞ app khi chưa chạy ---
appUrl := ""                      ; ĐIỀN địa chỉ trang, ví dụ "https://ten-ban.github.io/speech-to-text/"
browserExe := "chrome.exe"        ; cần trình duyệt có Web Speech API: "chrome.exe" hoặc "msedge.exe"

restorePrevWindow := true         ; false: ở lại cửa sổ app, không tự quay về
restoreTimeoutMs := 120000        ; bỏ theo dõi nếu quá lâu không dùng

prevHwnd := 0
sawListening := false
armedAt := 0

!Space:: {
    global prevHwnd, sawListening, armedAt
    cur := WinExist("A")
    appHwnd := WinExist(appTitle)
    if !appHwnd {
        if appUrl = "" {
            ToolTip "Chưa mở app, và chưa điền appUrl trong file .ahk"
            SetTimer () => ToolTip(), -2500
            return
        }
        ; Mở cửa sổ app độc lập (không thanh địa chỉ) bằng chính địa chỉ web, không cần shortcut.
        Run browserExe ' --app="' appUrl '"'
        appHwnd := WinWait(appTitle, , 10)
        if !appHwnd {
            ToolTip "Không mở được app (kiểm tra appUrl và browserExe)"
            SetTimer () => ToolTip(), -3000
            return
        }
        Sleep 800                 ; chờ trang tải xong để nhận phím Space
    }
    if cur != appHwnd
        prevHwnd := cur
    sawListening := false
    armedAt := A_TickCount
    WinActivate appHwnd
    WinWaitActive appHwnd, , 1
    if restorePrevWindow && prevHwnd
        SetTimer WatchApp, 150
}

; Theo dõi tiêu đề cửa sổ app để biết khi nào nói xong và copy xong.
WatchApp() {
    global prevHwnd, sawListening, armedAt
    appHwnd := WinExist(appTitle)
    if !appHwnd || !prevHwnd || A_TickCount - armedAt > restoreTimeoutMs {
        SetTimer WatchApp, 0
        prevHwnd := 0
        return
    }
    title := WinGetTitle(appHwnd)
    if InStr(title, "Đang nghe") {
        sawListening := true
        return
    }
    if InStr(title, "Chưa copy") {             ; copy lỗi: ở lại để bấm nút Copy
        SetTimer WatchApp, 0
        prevHwnd := 0
        return
    }
    ; "Đã copy", hoặc nghe xong mà không có chữ nào (tiêu đề về lại bình thường)
    done := InStr(title, "Đã copy") || (sawListening && !InStr(title, "Đang copy"))
    if done {
        SetTimer WatchApp, 0
        if WinExist("ahk_id " prevHwnd)
            WinActivate "ahk_id " prevHwnd
        prevHwnd := 0
    }
}
