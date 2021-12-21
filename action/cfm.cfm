<cfset uploadFolderPath = GetDirectoryFromPath(GetCurrentTemplatePath()) />
<cfset newFolder = uploadFolderPath & "\Dynamsoft_Upload\" />
<cffile action="upload" filefield="RemoteFile" destination="#newFolder#" nameconflict="OVERWRITE" />