Set objArgs = WScript.Arguments
Set objShell = CreateObject("WScript.Shell")

' Build the arguments string
args = ""
For i = 0 To objArgs.Count - 1
    args = args & " " & objArgs(i)
Next

' Construct the PowerShell command with arguments
cmd = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "".\entrypoint.ps1""" & args

' Run the command
objShell.Run cmd, 0, False
