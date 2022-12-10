#Include, %A_ScriptDir%\..\Rufaydium-Webdriver
#Include Rufaydium.ahk
Chrome := new Rufaydium()
Page := chrome.NewSession()
Page.WSConnect()
Page.Callback("TabCLose")
Page.URL := "https://www.autohotkey.com/boards/index.php"
Page.NewTab()
Page.URL := "https://www.google.com/"
Page.Callback("TabCLose")
return

F12::
Chrome.Driver.exit()
exitapp

TabCLose(event)
{
    global chrome, Page
    outputDebug, % r := event.data.PayloadText
    r := Json.load(r)
    if( r.method = "Inspector.detached" && r.params.reason = "target_closed")
    {
        
        MsgBox, 52,Rufaydium WebDriver Support,% "Event:" r.method "`nReason:" r.params.reason "`n`nPlease press Yes to Exit webdriver"
        IfMsgBox Yes
		{
            Page.ws.OnClose()
            Chrome.QuitAllSessions() ; close all session 
            Chrome.Driver.Exit() ; then exits driver
            msgbox, all session closed and script going to exit 
            return
        }
    }
}