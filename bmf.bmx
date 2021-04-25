Rem

------------------------------
BMF - Blitzmax code formatter
------------------------------

 - Created by:	Henri Vihonen
 - Version:		0.5.1 Beta

 * Description:

	Standalone code formatter for Blitzmax language that can be used by a code editor/IDE.
	BMF is a command line tool that can be used to format code files, or format code lines in real time.

 -Usage: See example folder

EndRem


'Start from command line
If AppArgs And AppArgs.length > 1 Then
	
	Local c:TBMaxCode = New TBMaxCode
	
	Local in:Int, out:Int, s:String, v:Int
	
	For Local arg:String = EachIn AppArgs
		
		arg = arg.Trim()	'.ToUpper()
		
		If arg.StartsWith("-") Then
			
			s = arg.Replace(" ", "").Replace("-", "").ToUpper()
			
			If s.StartsWith("STDIN") Then c.optStdIn = True
			If s.StartsWith("STDOUT") Then c.optStdOut = True
			If s.StartsWith("STDIO") Then c.optStdOut = True; c.optStdIn = True
			If s.StartsWith("I") Then in = True; out = False
			If s.StartsWith("O") Then in = False; out = True
			If s.StartsWith("V") Then v = True
			
		Else
			
			If in Then
				c.inUrl = arg
			ElseIf out
				c.outUrl = arg
			EndIf
		EndIf
		
	Next
	
	If v Then Print "Setting keywords.."
	c.SetKeywords()
	
	'Format a file
	'--------------
	If c.inUrl Then
		
		If v Then Print "Loading text.."
		
		Local text:String = LoadText(c.inUrl)
		If text Then
			
			text = c._parse(text)
			
			If c.outUrl Then
				SaveText(text, c.outUrl)
			Else
				SaveText(text, c.inUrl)
			EndIf
			
			If v Then
				Print "Saving text:"
				Print text + "~n"
			EndIf
		EndIf
	EndIf
	
	'Set to I/O mode 
	'----------------
	If c.optStdIn Then
	
		If v Then Print "Setting I/O mode active.."
		c.SetActive()
	EndIf
	
	If v Then Print "Ending.."
Else
	'Print "No args!"
EndIf 


Type TBMaxCode
	
	Const STYLE_KEYWORDS_1:Int = 1
	Const STYLE_KEYWORDS_2:Int = 2
	
	Global _autoKeywords:String					' Used for autocompletion
	Global _keywords1:String, _keywords2:String
	
	Global _traceType:String
	Global _wordList:TList = New TList

	Field _isMatch:Int, _isTraceable:Int
	
	Field inUrl:String, outUrl:String
	
	Field optAutoCap:Int = True
	Field optStdOut:Int
	Field optStdIn:Int
	
	Global mWrite:TMutex = TMutex.Create()
	
	Function GetAutoKeywords:String()
		Return _autoKeywords
	EndFunction
		
	Function GetKeywords:String(style:Int = STYLE_KEYWORDS_1)
		If style = STYLE_KEYWORDS_2 Then
			Return _keywords2
		Else
			Return _keywords1
		EndIf
	EndFunction
	
	Method GetWord:String(key:String)
		If Not key Then Return key
		
		Local tmpKey:String = key.tolower()
		
		For Local w:TWord = EachIn _wordList
			If w.key = tmpKey Then
				_isMatch = True
				If w.trace Then
					_isTraceable = True
					_traceType = tmpKey
				Else
					_isTraceable = False
					_traceType = ""
				EndIf
				
				Return w.name
			EndIf
		Next
		
		_isMatch = False
		_isTraceable = False
		
		Return key
	EndMethod
	
	Function InitKeywords()
	
		If Not _wordList.count() Then Return
		_wordList.sort(False)
		
		_autoKeywords = ""
		_keywords1 = ""
		_keywords2 = ""
		
		For Local w:TWord = EachIn _wordList
			
			If Not w.key Then Continue
			
			If _autoKeywords Then _autoKeywords:+ " "
			_autoKeywords:+ w.key
			
			If w.style = STYLE_KEYWORDS_2
				If _keywords2 Then _keywords2:+ " "
				_keywords2:+ w.key
			Else
				If _keywords1 Then _keywords1:+ " "
				_keywords1:+ w.key
			EndIf
		Next
	EndFunction
	
	Function LoadKeywords:Int(words:String, style:Int = STYLE_KEYWORDS_1)
		
		If Not words Then Notify "Error: Keywords not found.",True; Return False
		
		Local w:TWord
		Local ar:String[] = words.split(" ")
		
		If Not ar Then Notify "Error: Could not create keywords.",True; Return False
		
		For Local i:Int = 0 Until ar.length
			
			If Not ar[i].Trim() Then Continue
			
			w = New TWord
			w.style	= style
			w.name	= ar[i]
			w.key	= ar[i].tolower()
			
			_wordList.addlast(w)
		Next
		
		Return True
	EndFunction
	
	Method Parse:String(txt:String = "")
		
		If optStdIn Then 
			txt = ReadStdin()
		EndIf
		
		DebugLog "Parse: txt = " + txt
		
		Return _parse(txt)
		
	EndMethod
	
	Method SetActive()
		
		Local str:TBMFStream = TBMFStream.Create()
		Local s:String, isCatched:Int
		
		While True
			Try
				While True

					s = str.ReadString(1)   'myReadStdin()
					str.text.append(s)
					
					'WriteStdout( s + " = " + s[0] + "~n")
				Wend

			Catch o:Object
				
				isCatched = True
				WriteStdout(str.text.ToString())
				
			EndTry
			
			If Not isCatched Then
				WriteStdout(str.text.ToString())
			EndIf
			
			isCatched = False
		Wend
		
	EndMethod
	
	Method SetKeywords()
		
		Local keywords_1:String, keywords_2:String, traceWords:String
		
		keywords_1 = "Abs Abstract Alias And Asc Assert Case Catch Chr Const Continue DebugLog DebugStop Default DefData Delete EachIn " +..
					"Else ElseIf End EndExtern EndEnum EndFunction EndIf EndMethod EndRem EndSelect EndTry EndType Enum Exit Extends Extern " +..
					"False Field Final For Forever Framework Function Global Goto If Import Incbin IncbinLen IncbinPtr Include " +..
					"Len Local Max Method Min Mod Module ModuleInfo New Next Not Null Object Or Pi Print Private Public ReadData " +..
					"Release Rem Repeat RestoreData Return Sar Select Self Sgn Shl Shr SizeOf Step Strict Super SuperStrict Then Throw " +..
					"To True Try Type Until Var VarPtr Wend While"
					
		keywords_2 = "Byte Double Float Int Long Ptr Short String"
		
		traceWords = "Function Type Method Enum"
		
		LoadKeywords(keywords_1, STYLE_KEYWORDS_1)
		LoadKeywords(keywords_2, STYLE_KEYWORDS_2)
		SetTraceWords(traceWords)
		initKeywords()
		
	EndMethod
	
	Method SetOptions(options:String = "")
		
		options = options.Trim().toUpper()
		
		If options.contains("STDOUT") Then optStdOut = True
		If options.contains("STDIN") Then optStdIn = True
		
	EndMethod
	
	Method SetTraceWords:Int(words:String)
		If Not words Then Return False
		
		Local ar:String[] = words.split(" ")
		If Not ar Then Notify "Error: Could not set traceable keywords.",True; Return False
		
		For Local i:Int = 0 Until ar.length
			
			Local tmpKey:String = ar[i].Trim().tolower()
			If Not tmpKey Then Continue
			
			For Local w:TWord = EachIn _wordList
				If w.key = tmpKey Then
					w.trace = True; Exit
				EndIf
			Next
		Next
		
		Return True
	EndMethod
	
	Method _parse:String(txt:String Var, start:Int = 0)
			
		If Not txt Then Return txt
		
		Local startPos:Int = -1, lineCount:Int = start
		Local isString:Int, isCom:Int, isRem:Int, isNewline:Int, isEnd:Int
		Local isParam:Int
		Local isIdentifier:Int
		Local token:String, name:String, char:Int, analyze:Int, txt_ptr:Short Ptr = txt.ToWString()
		Local eol:Int = txt.length - 1
		
		For Local i:Int = 0 Until txt.length
			
			Select txt[i]
				
				Case 39 'Comment
					
					If isString Or isRem Then Continue			
					isCom = 1
					
				Case 34	'String
					
					If isCom Or isRem Then Continue
					isString = Not isString
					
					If isString And startPos > -1 Then
						analyze = 1
					Else
						startPos = -1
					EndIf

				Case 9, 32	'Tab, Space 
					
					If startPos > -1 And Not isIdentifier Then analyze = 1
					
				Case 10		'Newline
						
					isString = 0
					isCom = 0
					
					If startPos > -1 Then
						isNewline = 1
						analyze = 1
					Else
						isIdentifier = 0
						lineCount:+1
					EndIf
			
				Case 13, 59		' Return, Semicolon ';'
				
					If startPos > -1 Then analyze = 1
						
				Default
					
					If i = eol And startPos > -1 Then analyze = 1; i:+ 1
			
					isNewline = 0
					If isString Or isCom Then Continue
					If startPos = -1 Then startPos = i
					
			EndSelect
			
			'Words are analyzed at this point
			'--------------------------------
			If analyze Then
				
				analyze = 0
				name = txt[startPos..i]
				token = name.tolower()
				
				If Not isIdentifier Then
					
					If token = "end"
						isEnd = 1	'; Continue
					ElseIf token = "endrem" Or token = "end rem" Then
						isRem = 0
					ElseIf token = "rem"
						isRem = 1
					EndIf
					
					name = GetWord(token)
					If _isMatch Then
						If optAutoCap And name <> token Then
							For char = 0 Until token.length
								txt_ptr[startPos + char] = name[char]
							Next
						EndIf
						
						isIdentifier = _isTraceable
						
						If isIdentifier And isEnd Then
							isEnd = 0
							isIdentifier = 0
						EndIf
						
					Else
						'DebugLog "No match."
					EndIf
					
				Else
					'Name of the Method, Function etc.
					_parseTraceable(name, lineCount)
					isIdentifier = 0
				EndIf
				
				If isNewline Then
					isNewline = 0
					lineCount:+ 1
				EndIf
				
				startPos = -1
			EndIf
		Next
		
		If optStdOut Then
			
			mWrite.Lock()
			WriteStdout( txt.FromWString(txt_ptr) )
			mWrite.UnLock()
			
			Return ""
		Else	
			Return txt.FromWString(txt_ptr)
		EndIf
		
	EndMethod

	Method _parseTraceable(token:String, line:Int = -1)
		
		'DebugLog "ParseTraceable"
		
		Local traceType:String = _traceType
		
		If Not token Or Not traceType Or line = -1 Then Return
		
		Local key:String
		
		'Is a Function or a Method
		If token.contains("(")
			token = token.Replace(" ", "").Replace("~t", "").Replace(")", "") 
			Local ar1:String[] = token.split("(")
			Local ar2:String[] = ar1[0].split(":")
			Local par:String[] = ar1[1].split(",")
			
			key = traceType.tolower() + "_" + ar2[0]
			token = ":".join(ar2) + "(" + ", ".join(par) + ")"

		ElseIf token.contains(":")
			token = token.Replace(" ", "").Replace("~t", "")
			Local ar:String[] = token.split(":")		
		EndIf
		
		'DebugLog token + " | line = " + line + " | key = " + key + " | level = " + GetFoldLevel(line) + " | parent level = " + GetFoldParent(line)
		
		Local w:TWord = New TWord
		w.name = token
		w.key = key
		w.line = line
		'w.parentLine = GetFoldParent(line)
		
		'Local m:TModified = TModified.CreateWord(MODIFIED_TREE_ADD_TRACEABLE, w)
		'TExplorer.SetEvent(m)
	EndMethod
	
EndType

Type TWord
	
	Field style:Int
	Field name:String
	Field key:String
	Field trace:Int
	Field line:Int
	Field traceKey:String	
	
	Method compare:Int(o:Object)
		Local w:TWord = TWord(o)
		Return w.name.compare(Self.name)
	EndMethod
	
EndType

Type TBMFStream Extends TTextStream
	
	Global str:TBMFStream
	Global text:TStringBuilder = New TStringBuilder
	
	Function Create:TBMFStream()
		
		Local stream:TStream = New TCStandardIO
		
		str = New TBMFStream
		str._encoding = ETextStreamFormat.UTF8
		str.SetStream(stream)
		
		StandardIOStream = str
		
		Return str
	End Function

EndType
