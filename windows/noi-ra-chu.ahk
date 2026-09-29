; Phím tắt toàn cục cho app "Nói ra chữ" (AutoHotkey v2).
;   Alt+Space : đưa cửa sổ app lên trước và bắt đầu nói
;   Space     : (khi đang ở cửa sổ app) dừng nói; app tự copy, rồi script trả bạn về cửa sổ trước đó
; Lưu ý: cần mở sẵn app "Nói ra chữ" (cửa sổ PWA hoặc tab) và để nó chạy nền.
; Nếu bạn đang dùng AutoHotkey v1 thì báo lại để đổi cú pháp.

#Requires AutoHotkey v2.0
#SingleInstance Force
SetTitleMatchMode 2

appTitle := "Nói ra chữ"        ; trùng với <title> của trang
restorePrevWindow := true       ; true: sau khi dừng, quay lại cửa sổ đang làm việc trước đó
restoreDelayMs := 1800          ; chờ app copy xong (chốt an toàn của app là 1,5 giây)

prevHwnd := 0

!Space:: {
    global prevHwnd
    appHwnd := WinExist(appTitle)
    if !appHwnd {
        ToolTip "Chưa mở app Nói ra chữ"
        SetTimer () => ToolTip(), -1500
        return
    }
    cur := WinExist("A")
    if cur != appHwnd
        prevHwnd := cur
    WinActivate appHwnd
    WinWaitActive appHwnd, , 1
    KeyWait "Space", "T1"
    KeyWait "Alt", "T1"
    Send "{F9}"                 ; app coi F9 là "bắt đầu nói"
}

#HotIf WinActive(appTitle)
~Space:: {                      ; ~ để phím Space vẫn tới app (app dùng nó để dừng)
    if restorePrevWindow && prevHwnd
        SetTimer RestorePrev, -restoreDelayMs
}
#HotIf

RestorePrev() {
    global prevHwnd
    if prevHwnd && WinExist("ahk_id " prevHwnd)
        WinActivate "ahk_id " prevHwnd
    prevHwnd := 0
}
