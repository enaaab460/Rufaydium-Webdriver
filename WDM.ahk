Class RunDriver
{
    static visibility := "unknown until change"
    __New(Location,Parameters:= "--port=0")
    {
        if !FileExist(Location)
			if !instr(Location,".exe")
				Location .= ".exe"
        SplitPath(Location,&Name,&Dir,,&DriverName)
        this.Dir := Dir ? Dir : A_ScriptDir
        this.exe := Name
        if RegExMatch(Parameters, "--port=(\d+)",&P)
			this.param := p[1] ? p[0] : 0
        this.Name := DriverName

        switch this.Name
		{
			case "chromedriver" :
				this.Options := "goog:chromeOptions"
				this.browser := "chrome"
				if !this.param
					this.param := RegExReplace(Parameters, "(--port)=(\d+)", "$1=9515")
			case "msedgedriver" : 
				this.Options := "ms:edgeOptions"
				this.browser := "msedge"
				if !this.param
					this.param := RegExReplace(Parameters, "(--port)=(\d+)", "$1=9516")
			case "geckodriver" : 
				this.Options := "moz:firefoxOptions"
				this.browser := "firefox"
				if !this.param
					this.param := RegExReplace(Parameters, "(--port)=(\d+)", "$1=9517")
			case "operadriver" :
				this.Options := "goog:chromeOptions"
				this.browser := "opera"
				if !this.param
					this.param := RegExReplace(Parameters, "(--port)=(\d+)", "$1=9518")
			case "BraveDriver" :
				this.Options := "goog:chromeOptions"
				this.browser := "Brave"
				this.exe := "chromedriver.exe"
				if !this.param
					this.param := RegExReplace(Parameters, "(--port)=(\d+)", "$1=9515")	
			Default:
				if !this.param
					this.param := RegExReplace(Parameters, "(--port)=(\d+)", "$1=9519")
		}

        ; download needs to be here

        this.Target :=  this.Dir "\" Location " '" this.param "'"

        if RegExMatch(this.param,"--port=(\d+)",&port)
			This.Port := Port[1]
		else
		{
			Msgbox "Rufaydium WebDriver Support,Unable to download driver from`nURL :" this.DriverUrl "`nRufaydium exiting"
			ExitApp
		}

        PID := this.GetDriverbyPort(this.Port)
		if PID
		{
			this.PID := PID
            return this
		}
        this.Launch()
        this.visibility := 0
    }
    
    Exit()
    {
        ProcessClose this.PID
    }
    
    Delete()
    {
        ProcessClose this.PID
        FileDelete this.Dir "\" this.exe
    }

    Launch()
    {
        Run this.Target,, "Hide", &PID 
        ProcessWait(PID)
        this.PID := PID
    }
    
    visible
	{
		get => this.visibility

		set
		{
			if(value = 1) ;and !this.visible
			{
				WinShow "ahk_pid " this.pid
                this.visibility := 1
			}
			else
			{
				WinHide "ahk_pid " this.pid
                this.visibility := 0 
			}
		}
	}

    GetDriverbyPort(Port)
	{
		for process in ComObjGet("winmgmts:").ExecQuery("SELECT * FROM Win32_Process WHERE Name = '" this.exe "'")
		{
			RegExMatch(process.CommandLine, "(--port)=(\d+)",&p)
			if (Port != p[2])
			 	continue
			else
				return Process.processId
		}
	}
}