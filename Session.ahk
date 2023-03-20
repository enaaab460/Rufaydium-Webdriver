Class Session
{
    __New(address, debuggerAddress, name, websocketurl:=0)
    {
		this.defineprop('name', 			{ get : (this) => Name})
        this.defineprop('Address', 			{ get : (this) => address,			set : (this, value) => address := value})
		this.defineprop('debuggerAddress',	{ get : (this) => debuggerAddress,	set : (this, value) => debuggerAddress := value})
		currentTab := this.Send("window","GET")
		this.defineprop('currentTab', 		{ get : (this) => currentTab, 		set : (this, value) => currentTab := value})
		if websocketurl
			this.defineprop('websocketurl',{ get : (this) => websocketurl, set : (this, value) => websocketurl := value})
        return this
    }

    ; To quit Session
	Quit()
	{
		this.Send(this.address ,"DELETE")
	}

    ; To close tab or window
	close()
	{
		Tabs := this.Send("window","DELETE")
		this.Switch(this.currentTab := tabs[tabs.Length()])
	}

    Send(url,Method,Payload:= 0,WaitForResponse:=1)
	{
		if !instr(url,"HTTP")
			url := this.address "/" url
		if !Payload and (Method = "POST")
			Payload := Json.null
		try r := Json.parse(Rufaydium.Request(url,Method,Payload,WaitForResponse))["value"] ; Thanks to GeekDude for his awesome cJson.ahk
		if !r
			return
		t := ComObjType(r) 
		if t
		{
			v := ComObjValue(r)
			switch v
			{
				case 65535:
					return true
				case 0:
					switch t
					{
						case 11: return false
						case 1: return "null"
					}
			}
		}
		if isobject(r)
			if r.has("error")
				if (r["error"] = "chrome not reachable") ; incase someone close browser manually but session is not closed for driver
					this.quit() ; so we close session for driver at cost of one time response wait lag
		if r
			return r
	}

	Detail() 			=> Json.parse(this.Request(this.debuggerAddress "/json/list","GET"))
	GetTabs() 			=> this.Send("window/handles","GET")
	SwitchTab(Tabid)	=> this.Send("window","POST",map("handle",this.currentTab := Tabid))
	ActiveTab()  		=> this.SwitchTab("CDwindow-" this.Detail()[1].id )
	NewTab()			=> this.send("window/new","POST",map("type","tab"))["handle"]
	NewWindow()			=> this.send("window/new","POST",map("type","window"))["handle"]
	Minimize()			=> this.Send("window/minimize","POST",json.null)
	Maximize()			=> this.Send("window/maximize","POST",json.null)
	FullScreen()		=> this.Send("window/fullscreen","POST",json.null)
	GetRect()			=> this.Send("window/rect","GET")
	SetRect(x,y,w,h)	=> this.Send("window/rect","POST",map("x",x ?? 1,"y",y ?? 1,"width",w ?? 0,"height",h ?? 0))
	
	url
	{
		get => this.Send("url","GET")
		set => this.Send("url","POST",map("url",RegExReplace(Value,"^(?!\w+[:\/])(.*)","https://$1",,1)))
	}

	; to navigate to 1 or multiple urls Navigate(url1,url2,url3)
	Navigate(urls*)
	{
		for url in urls
			if a_index = 1
				this.url := RegExReplace(url,"^(?!\w+[:\/])(.*)","https://$1",,1)
			else
				this.CDPCall("Target.createTarget",map("url",RegExReplace(url,"^(?!\w+[:\/])(.*)","https://$1",,1)))
				
	}

	CreateTabs(urls*)
	{
		for url in urls
			this.CDPCall("Target.createTarget",map("url",RegExReplace(url,"^(?!\w+[:\/])(.*)","https://$1",,1)))
	}

	readyState
	{
		get => this.ExecuteSync("return document.readyState")
	}

	HTML
	{
		get => this.Send("source","GET",0,1)
	}

	Title
	{
		get => this.Send("title","GET")
	}

	Cookies[CookieMAP]
	{
		get => this.Send("cookie","GET")
		set => this.Send("cookie","POST",CookieMAP)
	}

	GetCookie(Name) => this.Send("cookie/" Name,"GET")

	Alert(Action,Text:=0)
	{
		switch Action
		{
			case "accept": i := "/alert/accept", m := "POST"
			case "dismiss": i := "/alert/dismiss", m := "POST"
			case "GET": i := "/alert/text", m := "GET"
			case "Send": i := "/alert/text", m := "POST"
		}

		if Text
			return this.Send(this.address i,m,map("text",Text))
		else
			return this.Send(this.address i,m)
	}

	ExecuteSync(Script,Args*) 	=> this.Send("execute/sync", "POST", map("script",Script,"args",[Args*]),1)
	ExecuteAsync(Script,Args*) 	=> this.Send("execute/async","POST", map("script",Script,"args",[Args*]),1)

	; element setting gettings
	ActiveElement()
	{
		for i, elementid in this.Send("element/active","GET")
			return Element(this.address "/element/" elementid,i)
	}

	shadow()
	{
		for i,  elementid in this.Send("shadow","GET")
		{
			return ShadowElement(this.address "/element/" elementid)
		}
	}

	findelement(u,v)
	{
		r := this.Send("element","POST",map("using",u,"value",v),1)
		for i, elementid in r
		{
			if instr(elementid,"no such")
				return 0
			return Element(this.address "/element/" elementid,i)
		}
	}

	findelements(u,v)
	{
		e := []
		for k, element in this.Send("elements","POST",map("using",u,"value",v),1)
		{
			for i, elementid in element
				e[k-1] := Element(this.address "/element/" elementid,i)
		}

		if e.count() > 0
			return e
		return 0
	}

	querySelector(path)					=> this.findelement(by.selector,Path)
	querySelectorAll(path)				=> this.findelements(by.selector,Path)
	getElementbyid(id) 					=> this.findelement(by.selector,"#" id)
	getElementsbyid(id) 				=> this.findelements(by.selector,"#" id)
	getElementsbyClassName(Class)		=> this.findelements(by.selector,"[class='" Class "']")
	getElementsbyTagName(Name)			=> this.findelements(by.TagName,Name)
	getElementsbyName(Name)				=> this.findelements(by.selector,"[Name='" Name "']")
	getElementsbyXpath(xPath)			=> this.findelements(by.xPath,xPath)
	getElementbyLinkText(Text)			=> this.findelement(by.linktext,Text)
	getElementsbyLinkText(Text)			=> this.findelements(by.linktext,Text)
	getElementbypLinkText(PartialText)	=> this.findelement(by.linktext,PartialText)
	getElementsbypLinkText(PartialText)	=> this.findelements(by.linktext,PartialText)
	
	; end getting element methods
	CDPCall(Method, Params:="")	=> this.Send("goog/cdp/execute","POST",map("cmd",Method,"params", Params ?? map()))
	Screenshot()				=> this.Send("screenshot","GET")

	CaptureFullSizeScreenShot(location)
	{
		this.CDPCall("Emulation.setDeviceMetricsOverride", map("width",this.Getrect().width,"height",this.ExecuteSync("return document.documentElement.scrollHeight")+0,"deviceScaleFactor",1,"mobile",json.false))
		base64 := this.Screenshot()
		this.CDPCall("Emulation.setDeviceMetricsOverride")
		return base64
	} 
}

Class by
{
	static selector := "css selector"
	static Linktext := "link text"
	static Plinktext := "partial link text"
	static TagName := "tag name"
	static XPath	:= "xpath"
}