<%@  page language="java" import="java.sql.*,java.io.*,java.util.*,org.apache.commons.fileupload.*,org.apache.commons.fileupload.disk.*,org.apache.commons.fileupload.servlet.*"%><%!
%><%
	// Determine how to process the request based on imgID
	String strImageID = request.getParameter("imgID");
	
	// Prepare credentials for connectiong to Oracle, here we use Oracle express (XE)
	String strDBUser = "dwtDB"; //database,schema name as well
	String strDBPassword = "Aa000000";
	String strDriverName = "oracle.jdbc.driver.OracleDriver";
	String strConnString = "jdbc:oracle:thin:@127.0.0.1:1521:XE";
	Connection conn=null;
	
	// Test Database Connection
	try
	{																	
		Class.forName(strDriverName).newInstance();									
		conn=DriverManager.getConnection(strConnString, strDBUser, strDBPassword);
		conn.setAutoCommit(true);
	}
	catch(Exception e)
	{
		out.println("An exception occurred: " + e.getMessage());
	}
	if(strImageID.equals("new"))
	{
		String fileName = "";
		long sizeInBytes = 0;
		// Create a factory for disk-based file items
		DiskFileItemFactory factory = new DiskFileItemFactory();

		// Configure a repository (to ensure a secure temp location is used)
		ServletContext servletContext = this.getServletConfig().getServletContext();
		File repository = (File) servletContext.getAttribute("javax.servlet.context.tempdir");
		factory.setRepository(repository);

		// Set factory constraints
		factory.setSizeThreshold(1000000000);// Sets the size threshold beyond which files are written directly to disk.

		// Create a new file upload handler
		ServletFileUpload upload = new ServletFileUpload(factory);

		// Set overall request size constraint
		upload.setSizeMax(-1);

		// Parse the request
		List<FileItem> items = upload.parseRequest(request);

		// Process the uploaded items
		Iterator<FileItem> iter = items.iterator();
		while (iter.hasNext()) {
			try{
				FileItem item = iter.next();				
				// Process a regular form field
				if (item.isFormField()) {} 			
				// Process a file upload
				else {
					fileName = item.getName();
					sizeInBytes = item.getSize();
					if(fileName != null && sizeInBytes != 0){
						InputStream stream_Input = item.getInputStream();
						byte[] buff = new byte[8000];
						int bytesRead = 0;
						ByteArrayOutputStream stream_BAO = new ByteArrayOutputStream();
						while((bytesRead = stream_Input.read(buff)) != -1) {
							stream_BAO.write(buff, 0, bytesRead);
						}
						byte[] data = stream_BAO.toByteArray();
						ByteArrayInputStream stream_BAI = new ByteArrayInputStream(data);
						stream_Input.close();
						PreparedStatement preparedStatement = conn.prepareStatement("insert into dwtsample(id, document_name, document_data) values(s_tblImage.NextVal, ?, ?)");
						preparedStatement.setString(1, fileName);
						preparedStatement.setBinaryStream(2, stream_BAI, stream_BAI.available());
						preparedStatement.executeUpdate();
						preparedStatement.close();
						
						Statement  stmt = conn.createStatement();
						ResultSet rs =stmt.executeQuery("select id from dwtsample");  
						int _imgIndex = 0;
						while (rs.next()){
							int _temp = rs.getInt("id");
							if(_temp > _imgIndex) {
								_imgIndex = _temp;
							}
						}
						Integer _fileSize = (int)(sizeInBytes/1024);
						String _strSize = Integer.toString(_fileSize) + "KB";
						conn.close();
						out.println("JSP:" + "DWTUploadFileIndex:" + Integer.toString(_imgIndex) + "DWTUploadFileName:" + fileName + "UploadedFileSize:" + _strSize);
					}
				}
			}
			catch(Exception e) 
			{ 	
				out.println("An exception occurred when saving to DB: " + e.getMessage());		
			}
		}
	}
	else {
		Statement sql_getData = conn.createStatement(); 
		ResultSet res_getData = sql_getData.executeQuery("select * from dwtsample where id =" + strImageID);
		
		String documentName = "";
		String strImageExtName = "";
		String strImg="";
		
		if (res_getData.next()){
			documentName = res_getData.getString("document_name");
			strImageExtName = documentName.substring(documentName.lastIndexOf(".") + 1);	
			Blob blob = res_getData.getBlob("document_data");
			InputStream steam_Input = blob.getBinaryStream();
			if (steam_Input != null) {
				BufferedInputStream stream_BufferInput = new BufferedInputStream(steam_Input);
				byte[] byte_buf = new byte[(int)blob.length()];
				stream_BufferInput.read(byte_buf);
				stream_BufferInput.close();
				conn.close();
				response.setHeader("Content-disposition", "attachment; filename=\"" + documentName + "\"");
				response.setHeader("Content-Length", String.valueOf(byte_buf.length));
				if(strImageExtName == "bmp"){
					response.setContentType("image/bmp");
				}else if(strImageExtName == "jpg"){
					response.setContentType("image/jpg");
				}else if(strImageExtName == "tif"){
					response.setContentType("image/tiff");
				}else if(strImageExtName == "png"){
					response.setContentType("image/png");
				}else if(strImageExtName == "pdf"){
					response.setContentType("application/pdf");
				}
				OutputStream stream_Output = response.getOutputStream();
				stream_Output.write(byte_buf, 0, byte_buf.length);
				stream_Output.flush();
				stream_Output.close();
			}
			else {
				out.println("<script language='javascript'>");
				out.println("alert('No image found!');");
				out.println("</script>");
			}
		}
	}
	
/* 
	create sequence S_TBLIMAGE
	minvalue 1
	maxvalue 999999999999999999999999999
	start with 1
	increment by 1
	cache 20
	order

	table creation
	CREATE TABLE dwtsample 
	(id NUMERIC(6),
	document_name VARCHAR(30), 
	document_data BLOB)
*/
%>
