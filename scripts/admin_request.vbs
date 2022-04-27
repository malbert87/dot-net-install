Set cmdArgs = WScript.Arguments.Unnamed
passArgs = ""
If cmdArgs.count > 1 Then
	For i = 1 to cmdArgs.count - 1
		passArgs = passArgs & cmdArgs.item(i) & " "
	Next
End If
Set UAC = CreateObject("Shell.Application")
UAC.ShellExecute cmdArgs.item(0), passArgs, "", "runas", 1