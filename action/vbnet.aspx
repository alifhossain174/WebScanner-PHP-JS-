<%@ Page Language="VB" %>

<%
    Try
        Dim strImageName As String, strImageSize As String
        Dim files As HttpFileCollection = HttpContext.Current.Request.Files
        Dim uploadfile As HttpPostedFile = files("RemoteFile")
        strImageName = uploadfile.FileName
        strImageSize = Convert.ToString(Convert.ToInt32(uploadfile.ContentLength / 1024)) + "KB"
        Dim strInputFile As String = Convert.ToString(Server.MapPath(".") + "\Dynamsoft_Upload\") & strImageName
        uploadfile.SaveAs(strInputFile)
        Dim path As String = strInputFile.Substring(0, strInputFile.Length - 4) + "_1.txt"
        Dim fieldsCount As Integer = HttpContext.Current.Request.Form.Count
        Dim _fields As String = ""
        If fieldsCount > 0 Then
            _fields = "FieldsTrue:"
            If Not System.IO.File.Exists(path) Then
                Using sw As System.IO.StreamWriter = System.IO.File.CreateText(path)
                    For i As Integer = 0 To fieldsCount - 1
                        ' Create a file to write to.
                        sw.WriteLine(HttpContext.Current.Request.Form.Keys(i) + " :  " + HttpContext.Current.Request.Form(HttpContext.Current.Request.Form.Keys(i)) + Environment.NewLine)
                    Next
                End Using
            End If
        End If
        Response.Write(_fields + "DWTUploadFileName:" + strImageName + "UploadedFileSize:" + strImageSize)
    Catch
    End Try
%>