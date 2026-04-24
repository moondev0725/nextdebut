Option Explicit
' Keep this file next to the project root. It starts the portable launcher.
Dim shell, fso, root, ps1, parent
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
root = fso.GetParentFolderName(WScript.ScriptFullName)
If Not fso.FileExists(root & "\tools\Launch_NEXTDEBUT.ps1") Then
    parent = fso.GetParentFolderName(root)
    If fso.FileExists(parent & "\tools\Launch_NEXTDEBUT.ps1") Then
        root = parent
    End If
End If
ps1 = root & "\tools\Launch_NEXTDEBUT.ps1"
If Not fso.FileExists(ps1) Then
    MsgBox "Missing file: " & ps1, vbCritical, "NEXTDEBUT"
    WScript.Quit 1
End If
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -Sta -WindowStyle Hidden -File """ & ps1 & """", 0, False
