
Rem
------------------------
 Example_02: StandardIO
------------------------

 -stdio option sets the I/O mode active
 -v option is for verbose and can be omitted

 * Note: Still work in progress..

EndRem

Local proc:TProcess = CreateProcess("bmf.exe -v -stdio")
If Not proc Then Print("Could not create bmf process"); End

Local feed:String, count:Int

If ProcessStatus(proc)
	
	Delay 100
	
	'Write to bmf
	proc.pipe.WriteString("print ~qHello world~q~n")
	
	Repeat
		If proc.pipe.ReadAvail() Then
			
			'Get formated text back
			feed:+ proc.pipe.ReadString(proc.pipe.ReadAvail())
		EndIf
		
		Delay 1000;
		If count > 3 Then Exit
		count:+ 1
		
		Print "Reading.." + count
	Forever
	
	proc.pipe.Close()
	
Else
	Print("bmf.exe not running. Exiting.."); End
EndIf

Delay 1000

DebugLog "bmf returned: " + feed + "~n"
DebugLog "Ending process.."

TerminateProcess(proc)

End
