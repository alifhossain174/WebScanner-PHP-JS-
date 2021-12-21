<!-- #include file="_clsUpload-db.asp" --><!--#include File="adovbs.inc"--><%  
If (Request.TotalBytes > 1) Then
	Dim objUpload, lngLoop

	Set objUpload = New clsUpload
	
	For lngLoop = 0 to objUpload.Files.Count - 1
	    objUpload.Files.Item(lngLoop).Save 
	Next
	
	Set objUpload = Nothing
end if
%>