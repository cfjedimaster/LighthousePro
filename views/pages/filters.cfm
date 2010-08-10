<cfset filters = event.getValue("filters")>

<cfcontent type="application/json" reset="true"><cfoutput>#helpers.json.encode(filters)#</cfoutput>