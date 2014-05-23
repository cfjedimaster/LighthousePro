<!--- 20131228 akh.com - Serve the attachment. Am I a model? Or am I technically a view?  Don't care! --->

<!--- attachment id is needed --->
<!---
<cfparam name="url.aid" default="" />
--->
<cfset aid = event.getValue("aid")>

<!--- get the attachments under this issue --->
<cfset issue = event.getValue("issue") />
<cfset attachments = issue.getAttachments() />

<!--- locate the filename for the one attachment identified in the url --->
<!--- I bet all this yearns to be a whole nuther method in the modelbeanbox framework --->
<cfquery dbtype="query" name="qGetFileNane">
	SELECT filename FROM attachments
	WHERE id = '#aid#'
</cfquery>

<cfif qGetFileNane.RecordCount>
	<!--- get the internal path for our attachments and send the file --->
	<cfset attachmentPath = viewState.getModelGlue().getBean("applicationSettings").getConfig().attachmentPath />
	<cfif fileExists(attachmentPath & '/' & qGetFileNane.filename)>
		<cfheader name="Content-Disposition" value="attachment; filename=#qGetFileNane.filename#" />
		<cfcontent file="#attachmentPath#/#qGetFileNane.filename#" deletefile="false" />
	<cfelse>
		<cfoutput>File #qGetFileNane.filename# was not found on the server</cfoutput>
	</cfif>
<cfelse>
	<cfoutput>Attachment #url.aid# was not found in the database</cfoutput>
</cfif>