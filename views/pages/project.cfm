
<cfset event.setValue("title", "Project Edit")>
<cfset errors = event.getValue("errors")>
<cfset root = event.getValue("myself")>
<cfset project = event.getValue("project")>
<cfset projectAreas = event.getValue("projectareas")>
<cfset issueTypes = event.getValue("issuetypes")>
<cfset statuses = event.getValue("statuses")>
<cfset severities = event.getValue("severities")>
<cfset users = event.getValue("users")>

<cfset name = event.getValue("name", project.getName())>
<cfset mailserver = event.getValue("mailserver", project.getMailServer())>
<cfset mailusername = event.getValue("mailusername", project.getMailUsername())>
<cfset mailpassword = event.getValue("mailpassword", project.getMailPassword())>
<cfset mailemailaddress = event.getValue("mailemailaddress", project.getMailEmailAddress())>

<cfset defaultLocus = project.getDefaultLocus()>
<cfset defaultSeverity = project.getDefaultSeverity()>
<cfset defaultStatus = project.getDefaultStatus()>
<cfset defaultIssueType = project.getDefaultIssueType()>

<cfset selProjectAreas = event.getValue("selprojectareas", project.getProjectAreas())>
<cfset selUsers = event.getValue("selusers", project.getUsers())>

<!---
Thought about updating the Default PA to reflect selected items.
Decided to be lazy. Will keep this code in here in case I change my 
mind later. For now, I'll use a warning - ie, don't pick a default you
don't actually support. I'll ensure the other code works though in case
you do.
<script>
function arrayFind(arr,val) {
	for(var i=0; i<arr.length; i++) {
		if(arr[i] == val) return i;
	}
	return -1;
}
$(document).ready(function() {

	$("#selectedprojectareas").change(function() {
		var currentValues = $(this).val();
		var defaultItem  = $("#defaultlocus")[0];
		console.dir(currentValues);
		for(var i=defaultItem.options.length-1;i>=1; i--) {
			if(arrayFind(currentValues, defaultItem.options[i].value) == -1) {
				defaultItem.remove(i);
			}
		}
	});
});
</script>	
--->

<h2 class="red">Project Edit</h2>
<p>
Use the form below to edit your project. Project Areas refer to the areas of your project where issues
may be located. Typical examples include "Database, Front End, Administrator, Components." Only
selected users will be able to work with issues.
</p>

<cf_renderErrors errors="#errors#">

<cfoutput>
<form action="#root#action.projectsave" method="post">
<input type="hidden" name="id" value="#project.getId()#">
<table id="formTable" cellspacing="4" cellpadding="4">
	<tr>
		<td align="right" width="120"><label>Name:</label></td>
		<td><input type="text" name="name" value="#name#" class="bigInput" maxlength="50"></td>
	</tr>
	<tr>
		<td align="right"><label>Project Area:</label></td>
		<td>
		<select name="selprojectareas" multiple size="5" class="input" id="selectedprojectareas">
		<cfloop query="projectAreas">
			<cfoutput><option value="#id#" <cfif listFind(selProjectAreas, id)>selected</cfif>>#name#</option></cfoutput>
		</cfloop>
		</select>
		</td>
	</tr>
	<tr>
		<td align="right"><label>Users:</label></td>
		<td>
		<select name="selusers" multiple size="5" class="input">
		<cfloop query="users">
			<cfoutput><option value="#id#" <cfif listFind(selUsers, id)>selected</cfif>>#username# (#name#)</option></cfoutput>
		</cfloop>
		</select>
		</td>
	</tr>
	<tr>
		<td colspan="2">
		Use the following fields to set up defaults for issues created in your project. New issues will use
		these defaults as well as any issue created via email. Note that selecting a default project area 
		that is not supported by the project will result in an invalid default for that setting.
		</td>
	</tr>
	<tr>
		<td align="right"><label>Default Project Area:</label></td>
		<td>
		<select name="defaultlocus" class="input" id="defaultlocus">
		<option value="" <cfif defaultLocus is "">selected</cfif>>None</option>
		<cfloop query="projectAreas">
			<cfoutput><option value="#id#" <cfif id is defaultLocus>selected</cfif>>#name#</option></cfoutput>
		</cfloop>
		</select>
		</td>
	</tr>
	<tr>
		<td align="right"><label>Default IssueType:</label></td>
		<td>
		<select name="defaultissuetype" class="input">
		<option value="" <cfif defaultIssueType is "">selected</cfif>>None</option>
		<cfloop query="issueTypes">
			<cfoutput><option value="#id#" <cfif id is defaultIssueType>selected</cfif>>#name#</option></cfoutput>
		</cfloop>
		</select>
		</td>
	</tr>	
	<tr>
		<td align="right"><label>Default Status:</label></td>
		<td>
		<select name="defaultstatus" class="input">
		<option value="" <cfif defaultstatus is "">selected</cfif>>None</option>
		<cfloop query="statuses">
			<cfoutput><option value="#id#" <cfif id is defaultStatus>selected</cfif>>#name#</option></cfoutput>
		</cfloop>
		</select>
		</td>
	</tr>
	<tr>
		<td align="right"><label>Default Severity:</label></td>
		<td>
		<select name="defaultseverity" class="input">
		<option value="" <cfif defaultSeverity is "">selected</cfif>>None</option>
		<cfloop query="severities">
			<cfoutput><option value="#id#" <cfif id is defaultSeverity>selected</cfif>>#name#</option></cfoutput>
		</cfloop>
		</select>
		</td>
	</tr>
	<tr>
		<td colspan="2">
		<p>
		Lighthouse Pro projects can be configured to check an email account for new issues. To enable this support, please complete
		all the fields below. Your mail username may be the same as your email address.
		</p>
		</td>
	</tr>
	<tr>
		<td align="right"><label>Mail Server:</label></td>
		<td><input type="text" name="mailserver" value="#mailserver#" class="input"></td>
	</tr>
	<tr>
		<td align="right"><label>Username:</label></td>
		<td><input type="text" name="mailusername" value="#mailusername#" class="input"></td>
	</tr>
	<tr>
		<td align="right"><label>Password:</label></td>
		<td><input type="password" name="mailpassword" value="#mailpassword#" class="input"></td>
	</tr>
	<tr>
		<td align="right"><label>Email Address:</label></td>
		<td><input type="text" name="mailemailaddress" value="#mailemailaddress#" class="input"></td>
	</tr>
	<tr>
		<td>&nbsp;</td>
		<td><input type="submit" name="Cancel" value="Cancel" class="button" /><input type="submit" name="save" value="Save" class="button blue"></td>
	</tr>
</table>
</form>
</cfoutput>

	