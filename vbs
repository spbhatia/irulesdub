Sub RunHealthCheck()

    Dim lastRow As Long
    Dim i As Long
    Dim server, path, port, fqdn, proto, url, hostHeader, curlCmd As String
    Dim result As String
    Dim shellOutput As String
    Dim getMethodCmd As String
    Dim tempFile As String
    
    ' Determine last used row in Column G (Server Name)
    lastRow = Cells(Rows.Count, "G").End(xlUp).Row

    For i = 6 To lastRow
        server = Cells(i, "G").Value
        path = Cells(i, "M").Value
        port = Cells(i, "I").Value
        fqdn = Cells(i, "E").Value
        proto = Cells(i, "K").Value
        url = proto & "://" & server & ":" & port & "/" & path
        hostHeader = "-H ""Host: " & fqdn & """"
        tempFile = Environ("TEMP") & "\curl_output.txt"
        
        ' HEAD Method with Host Header
        curlCmd = "cmd /c curl -I -k """ & url & """ " & hostHeader & " > """ & tempFile & """"
        Shell curlCmd, vbHide
        Application.Wait (Now + TimeValue("0:00:02"))
        shellOutput = ReadFile(tempFile)
        
        If InStr(shellOutput, "200") > 0 Then
            result = "Health check status is Up"
        
        ElseIf InStr(shellOutput, "401") > 0 Then
            result = "Authentication is on preventing server Health check"
        
        ElseIf InStr(shellOutput, "404") > 0 Then
            ' Try HEAD without Host Header
            curlCmd = "cmd /c curl -I -k """ & url & """ > """ & tempFile & """"
            Shell curlCmd, vbHide
            Application.Wait (Now + TimeValue("0:00:02"))
            shellOutput = ReadFile(tempFile)
            If InStr(shellOutput, "200") > 0 Then
                result = "Health check status is Up"
            Else
                result = "Health check status is Down (404)"
            End If
            
        ElseIf InStr(shellOutput, "405") > 0 Then
            ' Try GET method
            getMethodCmd = "cmd /c curl -i -k """ & url & """ " & hostHeader & " > """ & tempFile & """"
            Shell getMethodCmd, vbHide
            Application.Wait (Now + TimeValue("0:00:02"))
            shellOutput = ReadFile(tempFile)
            If InStr(shellOutput, "200") > 0 Then
                result = "HEAD not permitted, GET is permitted"
            Else
                result = "Health check status is Down"
            End If
        
        ElseIf InStr(shellOutput, "(7)") > 0 Or InStr(shellOutput, "(35)") > 0 Or InStr(shellOutput, "(60)") > 0 Then
            ' Try http instead of https
            url = "http://" & server & ":" & port & "/" & path
            curlCmd = "cmd /c curl -I -k """ & url & """ " & hostHeader & " > """ & tempFile & """"
            Shell curlCmd, vbHide
            Application.Wait (Now + TimeValue("0:00:02"))
            shellOutput = ReadFile(tempFile)
            If InStr(shellOutput, "200") > 0 Then
                result = "Down on https, Up on http"
            Else
                result = "Health check failed on both https and http"
            End If
            
        Else
            result = "Health check failed: Unknown response"
        End If
        
        Cells(i, "O").Value = result
    Next i

    MsgBox "Health Check Completed!"

End Sub

Function ReadFile(filePath As String) As String
    Dim fileNo As Integer
    Dim fileContent As String

    On Error Resume Next
    fileNo = FreeFile
    Open filePath For Input As #fileNo
    fileContent = Input$(LOF(fileNo), fileNo)
    Close #fileNo
    ReadFile = fileContent
End Function
