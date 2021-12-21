<%@ Page Language="c#" AutoEventWireup="false" %>

<%
    try
    {
        String strImageID = HttpContext.Current.Request["imgID"];

        String serverName = "TOMPC-EUROCOM";
        String userName = "test";
        String password = "Aa000000";
        String dbName = "dwtsample";
        String tableName = "uploadedimages";

        System.Data.SqlClient.SqlConnection tmpConn = new System.Data.SqlClient.SqlConnection("Data Source = " + serverName + ";User ID = " + userName + ";Pwd = " + password + ";");
        String sqlCreateDBQuery = string.Format("SELECT database_id FROM sys.databases WHERE Name = '{0}'", dbName);
        using (tmpConn)
        {
            using (System.Data.SqlClient.SqlCommand sqlCmd = new System.Data.SqlClient.SqlCommand(sqlCreateDBQuery, tmpConn))
            {
                tmpConn.Open();
                object resultObj = sqlCmd.ExecuteScalar();
                int databaseID = 0;
                if (resultObj != null)
                {
                    int.TryParse(resultObj.ToString(), out databaseID);
                }
                // Database doesn't exist, create one
                if (databaseID == 0)
                {
                    String sql_newdb = "CREATE DATABASE " + dbName;

                    using (System.Data.SqlClient.SqlCommand sqlcmd_newdb = new System.Data.SqlClient.SqlCommand(sql_newdb, tmpConn))
                    {
                        sqlcmd_newdb.ExecuteScalar();
                    }
                }
            }
            tmpConn.Close();
        }
        System.Data.SqlClient.SqlConnection Connection = new System.Data.SqlClient.SqlConnection("Data Source = " + serverName + ";User ID = " + userName + ";Pwd = " + password + ";Initial Catalog =" + dbName + ";");
        using (Connection)
        {
            Connection.Open();
            String sql_checkTable = @"IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES 
                       WHERE TABLE_NAME='" + tableName + "') SELECT 1 ELSE SELECT 0";
            using (System.Data.SqlClient.SqlCommand sqlcmd_checkTable = new System.Data.SqlClient.SqlCommand(sql_checkTable, Connection))
            {
                object result_obj = sqlcmd_checkTable.ExecuteScalar();
                int table_exists = 0;
                if (result_obj != null)
                {
                    int.TryParse(result_obj.ToString(), out table_exists);
                }
                // Table doesn't exist, create one
                if (table_exists == 0)
                {
                    String sql_newTable = @"CREATE TABLE " + tableName + " (id int NOT NULL IDENTITY (1, 1), document_name varchar(255) NOT NULL, document_data image NOT NULL) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]";
                    using (System.Data.SqlClient.SqlCommand sqlcmd_newTable = new System.Data.SqlClient.SqlCommand(sql_newTable, Connection))
                    {
                        sqlcmd_newTable.ExecuteScalar();
                    }
                }
            }
            if (strImageID == "new")
            {
                int iFileLength;
                HttpFileCollection files = HttpContext.Current.Request.Files;
                HttpPostedFile uploadfile = files["RemoteFile"];
                String strImageName = uploadfile.FileName;

                iFileLength = uploadfile.ContentLength;
                String strImageSize = Convert.ToString(Convert.ToInt32(iFileLength / 1024)) + "KB";
                Byte[] inputBuffer = new Byte[iFileLength];
                System.IO.Stream inputStream;
                inputStream = uploadfile.InputStream;
                inputStream.Read(inputBuffer, 0, iFileLength);
                inputStream.Close();
                String sql_insertData = "INSERT INTO " + tableName + " (document_name, document_data) VALUES (@document_name, @document_data)";
                using (System.Data.SqlClient.SqlCommand sqlcmd_insertData = new System.Data.SqlClient.SqlCommand(sql_insertData, Connection))
                {
                    sqlcmd_insertData.Parameters.Add("@document_data", System.Data.SqlDbType.Binary, iFileLength).Value = inputBuffer;
                    sqlcmd_insertData.Parameters.Add("@document_name", System.Data.SqlDbType.VarChar, 255).Value = strImageName;
                    sqlcmd_insertData.ExecuteScalar();
                }
                int imgIndex = 0;
                using (System.Data.SqlClient.SqlCommand sqlcmd_getIndex = new System.Data.SqlClient.SqlCommand("SELECT id FROM " + tableName, Connection))
                {
                    System.Data.SqlClient.SqlDataReader dataReader = sqlcmd_getIndex.ExecuteReader();

                    while (dataReader.Read())
                    {
                        int _temp = dataReader.GetInt32(0);
                        if (_temp > imgIndex)
                        {
                            imgIndex = _temp;
                        }
                    }
                }
                Connection.Close();

                Response.Write("CSHARP:" + "DWTUploadFileIndex:" + imgIndex.ToString() + "DWTUploadFileName:" + strImageName + "UploadedFileSize:" + strImageSize);
            }
            else
            {
                String sql_getData = "SELECT * FROM " + tableName + " WHERE id = " + strImageID;
                using (System.Data.SqlClient.SqlCommand sqlcmd_getData = new System.Data.SqlClient.SqlCommand(sql_getData, Connection))
                {
                    System.Data.SqlClient.SqlDataReader sdrRecordset = sqlcmd_getData.ExecuteReader();
                    sdrRecordset.Read();
                    String imgName = sdrRecordset["document_name"].ToString();
                    String imgNameExtension = imgName.Substring(imgName.LastIndexOf("."));
                    byte[] byFileData = (byte[])sdrRecordset["document_data"];

                    sdrRecordset.Close();
                    Connection.Close();

                    sdrRecordset = null;

                    Response.Clear();
                    Response.Buffer = true;

                    if (imgNameExtension == "bmp")
                    {
                        Response.ContentType = "image/bmp";
                    }
                    else if (imgNameExtension == "jpg")
                    {
                        Response.ContentType = "image/jpg";
                    }
                    else if (imgNameExtension == "tif")
                    {
                        Response.ContentType = "image/tiff";
                    }
                    else if (imgNameExtension == "png")
                    {
                        Response.ContentType = "image/png";
                    }
                    else if (imgNameExtension == "pdf")
                    {
                        Response.ContentType = "application/pdf";
                    }

                    try
                    {
                        String fileNameEncode;
                        fileNameEncode = HttpUtility.UrlEncode(imgName, System.Text.Encoding.UTF8);
                        fileNameEncode = fileNameEncode.Replace("+", "%20");
                        String appendedheader = "attachment;filename=" + fileNameEncode;
                        Response.AppendHeader("Content-Disposition", appendedheader);

                        Response.OutputStream.Write(byFileData, 0, byFileData.Length);
                    }
                    catch (Exception exc)
                    {
                        String strExc = exc.ToString();
                        DateTime d1 = DateTime.Now;
                        string logfilename = d1.Year.ToString() + d1.Month.ToString() + d1.Day.ToString() + d1.Hour.ToString() + d1.Minute.ToString() + d1.Second.ToString() + "log.txt";
                        String strField1Path = HttpContext.Current.Request.MapPath(".") + "/" + logfilename;
                        if (strField1Path != null)
                        {
                            System.IO.StreamWriter sw1 = System.IO.File.CreateText(strField1Path);
                            sw1.Write(strExc);
                            sw1.Close();
                        }
                        Response.Flush();
                        Response.Close();
                    }

                }
            }
        }
    }
    catch (System.Data.SqlClient.SqlException e)
    {
        Response.Write(e.ToString());
    }
%>