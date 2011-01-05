<cfset milestones = event.getValue("milestones")>
<cfset root = event.getValue("myself")>
<cfset project = event.getValue("project")>

<cf_datatable data="#milestones#" queryString="event=#event.getValue(event.getValue("eventValue"))#" editlink="#root#page.milestone&project=#project#" deletelink="#root#action.milestonedelete" label="Milestone" linkcol="name">
	<cf_datacol colname="name" label="name" />
	<cf_datacol colname="duedate" label="Due Date" format="date" />
</cf_datatable>
