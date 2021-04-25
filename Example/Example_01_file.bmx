
Rem
------------------
 Example_01: File
------------------

 -in option is for input file
 -out option is for optional output file
 -v option is for verbose and can be omitted

EndRem

'location of bmf.exe
'-------------------------------
Local bmf:String	= "bmf.exe"
'-------------------------------	

Local in:String		= "test_in.txt"
Local out:String	= "test_out.bmx"

If FileSize(bmf) = -1 Then Notify "bmf.exe not found", True; End

Local proc:TProcess = CreateProcess(bmf + " -v -in " + in + " -out " + out + " ")
If Not proc Then Print("Could not create bmf process. Ending.."); End

Local count:Int = 10, error:Int, feed:String

While ProcessStatus(proc)
	
	Print "Waiting " + count + " seconds.."
	Delay 1000
	count:- 1
	
	If proc.pipe.ReadAvail() Then
		
		'Get feedback if verbose option -v is enabled
		feed:+ proc.pipe.ReadString(proc.pipe.ReadAvail())
	EndIf
	
	If Not count Then
		Print "Process took too long. Ending process.."
		TerminateProcess(proc)
		error = True
	EndIf
Wend

If Not error And FileSize(out) <> -1 Then

	Print "File '" + out + "' created succesfully ."	
Else
	Print "Something went wrong.. ."	
EndIf

End
