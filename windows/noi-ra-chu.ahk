; Phím tắt toàn cục cho app "Nói ra chữ" (AutoHotkey v2).
;
; Cách dùng:
;   1. Đang ở bất kỳ cửa sổ nào, bấm Alt+Space -> app "Nói ra chữ" hiện lên trước.
;   2. Bấm Space -> bắt đầu nói.   Bấm Space lần nữa -> dừng, app tự copy.
;   3. Khi app báo "Đã copy", script tự đưa bạn về cửa sổ trước đó để dán (Ctrl+V).
;
; Nếu app chưa chạy, script tự mở app bằng shortcut đã cài của nó (FindAppShortcut).
; Nếu bạn đang dùng AutoHotkey v1 thì báo lại để đổi cú pháp.

#Requires AutoHotkey v2.0
#SingleInstance Force
SetTitleMatchMode 2

appTitle := "Nói ra chữ"        ; trùng với <title> của trang (app còn thêm tiền tố trạng thái)
launchIfNotRunning := true      ; app chưa chạy thì tự mở bằng shortcut đã cài (xem FindAppShortcut)
restorePrevWindow := true       ; false: ở lại cửa sổ app, không tự quay về
restoreTimeoutMs := 120000      ; bỏ theo dõi nếu quá lâu không dùng

prevHwnd := 0
sawListening := false
armedAt := 0

!Space:: {
    global prevHwnd, sawListening, armedAt
    cur := WinExist("A")
    appHwnd := WinExist(appTitle)
    if !appHwnd {
        lnk := launchIfNotRunning ? FindAppShortcut() : ""
        if !lnk {
            ToolTip "Chưa mở app Nói ra chữ (không tìm thấy shortcut để tự mở)"
            SetTimer () => ToolTip(), -2500
            return
        }
        ; App chưa chạy: mở bằng chính shortcut của app đã cài, không phụ thuộc vị trí taskbar.
        Run '"' lnk '"'
        appHwnd := WinWait(appTitle, , 10)
        if !appHwnd {
            ToolTip "Không mở được app từ: " lnk
            SetTimer () => ToolTip(), -3000
            return
        }
        Sleep 800               ; chờ trang tải xong để nhận phím Space
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

; Tìm shortcut của app "Nói ra chữ" ở các nơi trình duyệt/Windows thường đặt.
FindAppShortcut() {
    dirs := [
        A_AppData "\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar",   ; biểu tượng đã ghim ở taskbar
        A_Programs "\Chrome Apps",
        A_Programs "\Brave Apps",
        A_Programs "\Edge Apps",
        A_Programs,
        A_Desktop
    ]
    for dir in dirs {
        Loop Files, dir "\*Nói ra chữ*.lnk"
            return A_LoopFileFullPath
    }
    return ""
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
