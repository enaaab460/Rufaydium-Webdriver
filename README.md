# Rufaydium-Webdriver V2 Alpha
Rufaydium is a WebDriver Library for AutoHotkey V2 working only for chrome browser/chromeDriver for now.
User have to download chromedriver.exe

## Live JS bridge
Element.ahk aka Webdriver element all methods and properties from Webdriver have been pre-defined,
Undefined properties and Call method will be executed directly to Session Active Tab's JavaScript consol.

```Autohotkey
Chrome := Rufaydium() ; 
Page := Chrome.NewSession()
Page.url := "https://www.autohotkey.com/boards"
Ele1 := Page.querySelector("#search-box") ; get element from document
ele :=  Ele1.querySelector("#keywords") ; get element from element
ele.focus() ; this method is not been defined in element.ahk therefore will be called into JS console

X := "12345"
ele.value := X ; value is undefined property will be __Set the value of element in question using JS execution

ele.abc := '["a","b"]' ; this array is going to set inside JavaScript >> this ["a","b"] AHK array so it will throw error
msgbox ele.abc[0] ; __get "abc[0]" using JS console
ele.abc[0] := "c" ; __set "abc[0]" using JS console
msgbox ele.abc[0]

page.Quit() ; close page
Chrome.driver.Exit() ; close driver
exitapp
```
I wish I had time to write more
