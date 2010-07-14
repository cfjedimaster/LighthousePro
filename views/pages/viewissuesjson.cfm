
<cfset start = event.getValue("start",1)>
<cfset perpage = event.getValue("perpage",10)>
<cfset issues = event.getValue("issues")>
<cfset settings = event.getValue("settings")>

<!--- build a struct to hold metadata --->
<cfset s = structNew()>
<cfset s.total = issues.recordCount>

<!--- make the array to hold our data - pagination here kinda sucks --->
<cfset s.data = arrayNew(1)>
<cfif start gt s.total>
	<cfset start = 1>
</cfif>

<cfif s.total gt 0>
	<cfloop index="x" from="#start#" to="#min(s.total,start+perpage-1)#">
		<cfset i = structNew()>
		<cfset i.description = issues.description[x]>
		<cfset i.id = issues.id[x]>
		<cfset i.issuetype = issues.issuetype[x]>
		<cfset i.locusname = issues.locusname[x]>
		<cfset i.name = issues.name[x]>
		<cfset i.publicid = issues.publicid[x]>	
		<cfset i.severityname = issues.severityname[x]>
		<cfset i.severityrank = issues.severityrank[x]>		
		<cfset i.statusname = issues.statusname[x]>
		<cfset i.statusrank = issues.statusrank[x]>
		<cfset i.username = issues.username[x]>
		<cfif len(issues.updated[x])>
			<cfset i.prettydate = dateFormat(issues.updated[x], settings.dateformat)>
		<cfelse>
			<cfset i.prettydate = "">
		</cfif>
		<cfif len(issues.duedate[x])>
			<cfset i.prettyduedate = dateFormat(issues.duedate[x], settings.dateformat)>
		<cfelse>
			<cfset i.prettyduedate = "">
		</cfif>
		<cfset arrayAppend(s.data, i)>
	</cfloop>
</cfif>

<cfset issuesJSON = helpers.json.encode(s)>
<cfcontent type="application/json;charset=iso-8859-1" reset="true"><cfoutput>#issuesJSON#</cfoutput>