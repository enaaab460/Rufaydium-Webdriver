; Rufaydium V2 Alpha for AHK V2 Supported only for Chrome
; User have to download chromedriver.exe manually
; I will be testing this version and shared if someone like to point out issue in case over look by me.
#Requires AutoHotkey v2+
#Include ".\WDM.ahk"
#Include ".\Capabilities.ahk"
#Include ".\JSON.ahk"
#Include ".\Session.ahk"
#include ".\Elements.ahk"

Class Rufaydium
{
    static WebRequest := ComObject('WinHttp.WinHttpRequest.5.1')

    __New(DriverName:="chromedriver.exe",Parameters:="--port=0")
    {
        
        this.Driver := RunDriver(DriverName,Parameters)
		this.DriverUrl := "http://127.0.0.1:" This.Driver.Port
        Switch this.Driver.Name
		{
			case "chromedriver" :
				this.capabilities := ChromeCapabilities(this.Driver.browser,this.Driver.Options)
			case "msedgedriver" :
				;this.capabilities := EdgeCapabilities(this.Driver.browser,this.Driver.Options)
			case "geckodriver" :
                msgbox "geckodriver capabilities are under constructions`npress ok to exit driver"
                this.Driver.exit()
                return 0
				;this.capabilities := FireFoxCapabilities(this.Driver.browser,this.Driver.Options)
			case "operadriver" :
				;this.capabilities := OperaCapabilities(this.Driver.browser,this.Driver.Options)
			case "BraveDriver" :
				;this.capabilities := BraveCapabilities(this.Driver.browser,this.Driver.Options)
				;this.capabilities.Setbinary("C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe") 
				; drive might crash for 32 Brave on 64 bit OS there for we can load binary while new session, 
				; i.e. >> NewSession("32bit brave browser exe location")
			this.Driver.Location := this.Driver.GetPath() ;this.Driver.Dir "\" this.Driver.exe
				if !isobject(cap := this.capabilities.cap)
					this.capabilities := capabilities.Simple
		}
    }
    
	SetTimeouts(ResolveTimeout:=3000,ConnectTimeout:=3000,SendTimeout:=3000,ReceiveTimeout:=3000)
	{
		Rufaydium.WebRequest.SetTimeouts(ResolveTimeout,ConnectTimeout,SendTimeout,ReceiveTimeout)
	}

	Send(url,Method,Payload:= 0,WaitForResponse:=1)
	{
		if !instr(url,"HTTP")
			url := this.address "/" url
		if !Payload and (Method = "POST")
			Payload := Json.null
		try r := Json.parse(Rufaydium.Request(url,Method,Payload,WaitForResponse))["value"] ; Thanks to GeekDude for his awesome cJson.ahk
		if r.has("error")
			if (r["error"] = "chrome not reachable") ; incase someone close browser manually but session is not closed for driver
				this.quit() ; so we close session for driver at cost of one time response wait lag
		if r
			return r
	}

	static Request(url,Method,p:=0,w:=0)
	{
		Rufaydium.WebRequest.Open(Method, url, false)
		Rufaydium.WebRequest.SetRequestHeader("Content-Type","application/json")
		if p
		{
			p := RegExReplace(json.stringify(p),"\\\\uE(\d+)","\uE$1")  ; fixing Keys turn '\\uE000' into '\uE000'
			Rufaydium.WebRequest.Send(p)
		}
		else
			Rufaydium.WebRequest.Send()
		if w
			Rufaydium.WebRequest.WaitForResponse()
		return Rufaydium.WebRequest.responseText
	}

	NewSession(Binary:="")
	{
		if !this.capabilities.options
		{

			Msgbox("Unknown Driver Loaded`n.Please read readme and manually set capabilities for " this.Driver.Name ".exe" ,"Rufaydium WebDriver Support", 64)
			return
		}
		;if Binary
			;this.capabilities.Setbinary(Binary)
		this.Driver.Options := this.capabilities.options
		r := this.Send( this.DriverUrl "/session","POST",this.capabilities.cap,1) ; r = reponse
		if r.has("error")
		{
			msgbox( r["error"] "`n`n" r["message"],"Rufaydium WebDriver Support Error",48)
			return r
		}

		;window["DriverPID"] := This.driver.PID
		if This.driver.Name = "geckodriver"
		{
			debuggerAddress := "http://" r["capabilities"]["moz:debuggerAddress"]
			;IniWrite, % window["debuggerAddress"], % this.driver.dir "/ActiveSessions.ini", % This.driver.Name, % r["SessionId"]
		}
		else
			debuggerAddress := StrReplace(r["capabilities"][this.driver.options]["debuggerAddress"],"localhost","http://127.0.0.1")
		if r["capabilities"].has("websocketurl")
			websocketurl := r["capabilities"]["websocketurl"]
		else
			websocketurl := 0
		return Session(this.DriverUrl "/session/" r["sessionId"], debuggerAddress,This.driver.Name,websocketurl)
	}

	Exit() => this.Driver.Exit()
	
}