<%@ Page Language="VB" AutoEventWireup="false" %>

<%

    Try
        Dim strImageID As [String] = HttpContext.Current.Request("imgID")

        Dim serverName As [String] = "TOMPC-EUROCOM"
        Dim userName As [String] = "test"
        Dim password As [String] = "Aa000000"
        Dim dbName As [String] = "dwtsample"
        Dim tableName As [String] = "uploadedimages"

        Dim tmpConn As New System.Data.SqlClient.SqlConnection("Data Source = " + serverName + ";User ID = " + userName + ";Pwd = " + password + ";")
        Dim sqlCreateDBQuery As [String] = String.Format("SELECT database_id FROM sys.databases WHERE Name = '{0}'", dbName)
        Using tmpConn
            Using sqlCmd As New System.Data.SqlClient.SqlCommand(sqlCreateDBQuery, tmpConn)
                tmpConn.Open()
                Dim resultObj As Object = sqlCmd.ExecuteScalar()
                Dim databaseID As Integer = 0
                If resultObj IsNot Nothing Then
                    Integer.TryParse(resultObj.ToString(), databaseID)
                End If
                ' Database doesn't exist, create one
                If databaseID = 0 Then
                    Dim sql_newdb As [String] = "CREATE DATABASE " + dbName

                    Using sqlcmd_newdb As New System.Data.SqlClient.SqlCommand(sql_newdb, tmpConn)
                        sqlcmd_newdb.ExecuteScalar()
                    End Using
                End If
            End Using
            tmpConn.Close()
        End Using
        Dim Connection As New System.Data.SqlClient.SqlConnection("Data Source = " + serverName + ";User ID = " + userName + ";Pwd = " + password + ";Initial Catalog =" + dbName + ";")
        Using Connection
            Connection.Open()
            Dim sql_checkTable As [String] = "IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES " & vbCr & vbLf & "                       WHERE TABLE_NAME='" + tableName + "') SELECT 1 ELSE SELECT 0"
            Using sqlcmd_checkTable As New System.Data.SqlClient.SqlCommand(sql_checkTable, Connection)
                Dim result_obj As Object = sqlcmd_checkTable.ExecuteScalar()
                Dim table_exists As Integer = 0
                If result_obj IsNot Nothing Then
                    Integer.TryParse(result_obj.ToString(), table_exists)
                End If
                ' Table doesn't exist, create one
                If table_exists = 0 Then
                    Dim sql_newTable As [String] = "CREATE TABLE " + tableName + " (id int NOT NULL IDENTITY (1, 1), document_name varchar(255) NOT NULL, document_data image NOT NULL) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]"
                    Using sqlcmd_newTable As New System.Data.SqlClient.SqlCommand(sql_newTable, Connection)
                        sqlcmd_newTable.ExecuteScalar()
                    End Using
                End If
            End Using
            If strImageID = "new" Then
                Dim iFileLength As Integer
                Dim files As HttpFileCollection = HttpContext.Current.Request.Files
                Dim uploadfile As HttpPostedFile = files("RemoteFile")
                Dim strImageName As [String] = uploadfile.FileName

                iFileLength = uploadfile.ContentLength
                Dim strImageSize As [String] = Convert.ToString(Convert.ToInt32(iFileLength / 1024)) + "KB"
                Dim inputBuffer As [Byte]() = New [Byte](iFileLength - 1) {}
                Dim inputStream As System.IO.Stream
                inputStream = uploadfile.InputStream
                inputStream.Read(inputBuffer, 0, iFileLength)
                inputStream.Close()
                Dim sql_insertData As [String] = "INSERT INTO " + tableName + " (document_name, document_data) VALUES (@document_name, @document_data)"
                Using sqlcmd_insertData As New System.Data.SqlClient.SqlCommand(sql_insertData, Connection)
                    sqlcmd_insertData.Parameters.Add("@document_data", System.Data.SqlDbType.Binary, iFileLength).Value = inputBuffer
                    sqlcmd_insertData.Parameters.Add("@document_name", System.Data.SqlDbType.VarChar, 255).Value = strImageName
                    sqlcmd_insertData.ExecuteScalar()
                End Using
                Dim imgIndex As Integer = 0
                Using sqlcmd_getIndex As New System.Data.SqlClient.SqlCommand("SELECT id FROM " + tableName, Connection)
                    Dim dataReader As System.Data.SqlClient.SqlDataReader = sqlcmd_getIndex.ExecuteReader()

                    While dataReader.Read()
                        Dim _temp As Integer = dataReader.GetInt32(0)
                        If _temp > imgIndex Then
                            imgIndex = _temp
                        End If
                    End While
                End Using
                Connection.Close()

                Response.Write("VBNET:" + "DWTUploadFileIndex:" + imgIndex.ToString() + "DWTUploadFileName:" + strImageName + "UploadedFileSize:" + strImageSize)
            Else
                Dim sql_getData As [String] = "SELECT * FROM " + tableName + " WHERE id = " + strImageID
                Using sqlcmd_getData As New System.Data.SqlClient.SqlCommand(sql_getData, Connection)
                    Dim sdrRecordset As System.Data.SqlClient.SqlDataReader = sqlcmd_getData.ExecuteReader()
                    sdrRecordset.Read()
                    Dim imgName As [String] = sdrRecordset("document_name").ToString()
                    Dim imgNameExtension As [String] = imgName.Substring(imgName.LastIndexOf("."))
                    Dim byFileData As Byte() = DirectCast(sdrRecordset("document_data"), Byte())

                    sdrRecordset.Close()
                    Connection.Close()

                    sdrRecordset = Nothing

                    Response.Clear()
                    Response.Buffer = True

                    If imgNameExtension = "bmp" Then
                        Response.ContentType = "image/bmp"
                    ElseIf imgNameExtension = "jpg" Then
                        Response.ContentType = "image/jpg"
                    ElseIf imgNameExtension = "tif" Then
                        Response.ContentType = "image/tiff"
                    ElseIf imgNameExtension = "png" Then
                        Response.ContentType = "image/png"
                    ElseIf imgNameExtension = "pdf" Then
                        Response.ContentType = "application/pdf"
                    End If

                    Try
                        Dim fileNameEncode As [String]
                        fileNameEncode = HttpUtility.UrlEncode(imgName, System.Text.Encoding.UTF8)
                        fileNameEncode = fileNameEncode.Replace("+", "%20")
                        Dim appendedheader As [String] = "attachment;filename=" + fileNameEncode
                        Response.AppendHeader("Content-Disposition", appendedheader)

                        Response.OutputStream.Write(byFileData, 0, byFileData.Length)
                    Catch exc As Exception
                        Dim strExc As [String] = exc.ToString()
                        Dim d1 As DateTime = DateTime.Now
                        Dim logfilename As String = d1.Year.ToString() + d1.Month.ToString() + d1.Day.ToString() + d1.Hour.ToString() + d1.Minute.ToString() + d1.Second.ToString() + "log.txt"
                        Dim strField1Path As [String] = Convert.ToString(HttpContext.Current.Request.MapPath(".") + "/") & logfilename
                        If strField1Path IsNot Nothing Then
                            Dim sw1 As System.IO.StreamWriter = System.IO.File.CreateText(strField1Path)
                            sw1.Write(strExc)
                            sw1.Close()
                        End If
                        Response.Flush()
                        Response.Close()

                    End Try
                End Using
            End If
        End Using
    Catch e As System.Data.SqlClient.SqlException
        Response.Write(e.ToString())
    End Try
%>