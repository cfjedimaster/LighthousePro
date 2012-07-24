<cfset root = event.getValue("myself")>
<cfset project = event.getValue("project")>

<cfset currentfilters = event.getValue("currentfilters")>
<cfset possibleIssueTypes = event.getValue("issuetypes")>
<cfset issuetype_filter = event.getValue("issuetype_filter",currentfilters.issuetype_filter)>

<cfset allProjectAreas = event.getValue("projectareas")> 
<cfset possibleProjectAreas = project.getProjectAreas()>
<cfset loci_filter = event.getValue("loci_filter",currentfilters.loci_filter)>

<cfset possibleSeverities = event.getValue("severities")>
<cfset severity_filter = event.getValue("severity_filter",currentfilters.severity_filter)>

<cfset possibleStatuses = event.getValue("statuses")>
<cfset status_filter = event.getValue("status_filter",currentfilters.status_filter)>

<cfset possibleUsers = project.getFullUsers()>
<cfset owner_filter = event.getValue("owner_filter",currentfilters.owner_filter)>

<cfset perpage = event.getValue("perpage", currentfilters.perpage_filter)>

<cfset milestones = event.getValue("milestones")>
<cfset milestone_filter = event.getValue("milestone_filter",currentfilters.milestone_filter)>

<cfset keyword_filter = event.getValue("keyword_filter",currentfilters.keyword_filter)>
<cfset archived_filter = event.getValue("archived_filter",currentfilters.archived_filter)>

<cfset event.setValue("title", "Issues for Project: #project.getName()#")>

<cfoutput>

<script>
var issuesurl = "#root#page.viewissues&requestformat=json&id=#project.getID()#&stupid=#rand("SHA1PRNG")#";
var projectid = "#project.getId()#";
var sort = "prettydate";
var sortdir = "desc";
var issuetype = "";
var locus = "";
var severity = "";
var status = "";
var owner = "";
var keyword = "";
var milestone = "";
var istart = 1;
var perpage = #perpage#;
var archived = 0;

//this handle checking to see if you can delete issues. makes sure you checked something
//deleting removed from display, but keeping js for now
function checksubmit() {
	
	if(document.listing.mark.length == null) {
		if(document.listing.mark.checked) {
			document.listing.submit();
			return;
		}
	}

	for(i=0; i < document.listing.mark.length; i++) {
		if(document.listing.mark[i].checked) document.listing.submit();
	}
}

function checkprint() {		
	if($("##forprint").val() == '') { alert("There are no issues to print!"); return false; }
	return true;
}

function getURL() {
	var url = issuesurl + "&sort=" + sort + "&sortdir=" + sortdir;
	if(issuetype.length > 0) url+="&issuetype=" + issuetype;
	if(locus.length > 0) url+="&locus=" + locus;
	if(severity.length > 0) url+="&severity=" + severity;
	if(status.length > 0) url+="&status=" + status;
	if(owner.length > 0) url+="&owner=" + owner;
	if(keyword.length > 0) url+="&keyword=" + escape(keyword);
	<cfif milestones.recordCount>
	if(milestone.length > 0) url+="&milestone=" + milestone;
	</cfif>
	if(archived === 1) url+="&archived=1";
	url += "&start="+istart;
	url += "&perpage="+perpage;
	return url; 
}	

function displayData(data,textStatus) { 
	var datatotal = data.DATA.length;
	var grandtotal = data.TOTAL;
	var s = "";

	$("##forprint").val("");
	
	for(var i=0; i<datatotal; i++) {
		s+= "<tr";
		if(i%2==0) s+=">";
		else s+=" class=\"dark\">";
		s+= "<td>" +data.DATA[i]["PUBLICID"];
		s+= "</td><td><a href=\"#root#page.viewissue&id="+data.DATA[i]["ID"]+"&pid=#project.getID()#\">" + data.DATA[i]["NAME"];
		s+= "</td><td>" + data.DATA[i]["ISSUETYPE"];
		s+= "</td><td>" + data.DATA[i]["LOCUSNAME"];
		s+= "</td><td>" + data.DATA[i]["SEVERITYNAME"];
		s+= "</td><td>" + data.DATA[i]["STATUSNAME"];
		s+= "</td><td>" + data.DATA[i]["USERNAME"];
		s+= "</td><td>" + data.DATA[i]["PRETTYDUEDATE"];
		s+= "</td><td>" + data.DATA[i]["PRETTYDATE"];
		s+= "</td></tr>";

		//update hidden print field
		currentfp = $("##forprint").val();
		if(currentfp == "") $("##forprint").val(data.DATA[i]["ID"]);
		else $("##forprint").val(currentfp+","+data.DATA[i]["ID"]);

	}
	$("##datadisplay").empty();		
	$("##datadisplay").append(s);
	$("##loading").hide();
	
	if(grandtotal != 0) {
		s = "Showing " + istart + " to ";
		if(istart + perpage > grandtotal) s += grandtotal;
		else s += istart+perpage-1;	
		
		s+= " of " + grandtotal;
	} else {
		s = "";
	}			
	$("##pagination").empty();
	$("##pagination").append(s);
	
	if(istart > 1) $("##prevbutton").attr("disabled","");
	else $("##prevbutton").attr("disabled","true");

	if(istart + (perpage-1) > data.TOTAL) $("##nextbutton").attr("disabled","true");
	else $("##nextbutton").attr("disabled",""); 
	
}

function filterData() {
	issuetype = $("##issuetype_filter").val();
	locus = $("##loci_filter").val();
	severity = $("##severity_filter").val();
	status = $("##status_filter").val();
	owner = $("##owner_filter").val();
	keyword = $("##keyword_filter").val();
	milestone = $("##milestone_filter").val();
	perpage = parseInt($("##perpage_filter").val());
	if($("##archived_filter").attr("checked")) {
		archived=1;
	} else {
		archived=0;
	}

	istart=1;
	updatePage(istart);
}

function loadData() { 
	$("##loading").show();
	$.getJSON(getURL(),displayData);
}

function sortData(c) {
	if(sort == c) sortdir = (sortdir=="asc")?"desc":"asc";
	else sortdir = "asc";
	sort = c;
	loadData();
}

function updatePage(n) { 
	if(n < 1) istart = 1;
	else istart = n; 
	loadData();
}

$(document).ready(function() {

		$.ajaxSetup({
			error:function(x,e){
				if(x.status == 500 && x.statusText == "SessionTimeout") {
					alert("Your session has timed out.");
					location.href = 'index.cfm';
				}
			}
		});
	
		filterData();

		$("##newFilterForm").dialog({
			autoOpen:false,
			modal:true,
			buttons: {
				Save:function() {
					//first, get the value. if blank, we are going to treat like a cancel
					var filterName = $("##newFilterName").val();
					filterName = $.trim(filterName);
					if(filterName == '') { $(this).dialog('close'); return; }

					//gather the data we will see to create this filter
					var filter = {};
					filter.name = filterName;
					filter.projectid = projectid;
					filter.issuetype = $("##issuetype_filter").val();
					filter.locus = $("##loci_filter").val();
					filter.severity = $("##severity_filter").val();
					filter.status = $("##status_filter").val();
					filter.owner = $("##owner_filter").val();
					filter.keyword = $("##keyword_filter").val();
					filter.milestone = $("##milestone_filter").val();
					filter.perpage = parseInt($("##perpage_filter").val());
					if($("##archived_filter").attr("checked")) {
						filter.archived=1;
					} else {
						filter.archived=0;
					}

					//store our filter
					$.post("#root#action.filterSave", filter, function(res,status) {
						//reload the filters nav so people know crap was saved
						reloadFilters();
						alert('Your filter, '+filterName+' was saved.');
					});

					$("##newFilterName").val('');
					$(this).dialog('close');
				},
				Cancel:function() {
					$("##newFilterName").val('');
					$(this).dialog('close');
				}
			}
		});
				
		$("##saveFilter").click(function(e) {
			$("##newFilterForm").dialog("open");
			e.preventDefault();
		});
	}
);
</script>
	
<h2 class="red">#project.getName()#</h2>

<p>
<form action="" method="get" name="projectform">
<fieldset>
	
	<legend>Filter Issues</legend>	
	<input type="hidden" name="filter" value="y">
	<select name="issuetype_filter" id="issuetype_filter" onChange="filterData()">
	<option value="">All Issue Types</option>
	<cfloop query="possibleIssueTypes">
		<option value="#id#" <cfif issuetype_filter is id>selected</cfif>>#name#</option>
	</cfloop>
	</select>
				
	<select name="loci_filter" id="loci_filter" onChange="filterData()">
	<option value="">All Areas</option>
	<cfloop query="allProjectAreas">
		<cfif listFind(possibleProjectAreas, id)>
			<option value="#id#" <cfif loci_filter is id>selected</cfif>>#name#</option>
		</cfif>
	</cfloop>
	</select>
				
	<select name="severity_filter" id="severity_filter" onChange="filterData()">
	<option value="">All Severities</option>
	<cfloop query="possibleSeverities">
		<option value="#id#" <cfif severity_filter is id>selected</cfif>>#name#</option>
	</cfloop>
	</select>

	<select name="status_filter" id="status_filter" onChange="filterData()">
	<option value="">All Statuses</option>
	<cfloop query="possibleStatuses">
		<option value="#id#" <cfif status_filter is id>selected</cfif>>#name#</option>
	</cfloop>
	</select>

	<select name="owner_filter" id="owner_filter" onChange="filterData()">
	<option value="">All Users</option>
	<cfloop query="possibleUsers">
		<option value="#id#" <cfif owner_filter is id>selected</cfif>>#name#</option>
	</cfloop>
	</select>
	
	<select name="perpage_filter" id="perpage_filter" onChange="filterData()">
	<option value="10">Show 10 results</option>
	<cfloop from="20" to="100" step="10" index="i">
		<option value="#i#" <cfif perpage is i>selected</cfif>>Show #i# results</option>
	</cfloop>
	</select>
	<br /><br />

	<cfif milestones.recordCount>
	<select name="milestone_filter" id="milestone_filter" onChange="filterData()">
	<option value="">All Milestones</option>
	<cfloop query="milestones">
		<option value="#id#" <cfif milestone_filter is id>selected</cfif>>#name#</option>
	</cfloop>
	</select>
	</cfif>
	
	<input type="text" id="keyword_filter" name="keyword_filter" value="#keyword_filter#" onkeyup="filterData()"> <input type="button" value="Keyword Search" onclick="filterData()">
	<input type="checkbox" id="archived_filter" name="archived_filter" value="1" onChange="filterData()" <cfif isBoolean(archived_filter) and archived_filter>checked</cfif>> Include Archived Issues
	<span id="loading"><img src="images/ajax-loader.gif" align="absmiddle"></span>
	<a href="" id="saveFilter">[Save as Filter]</a>

</fieldset>
</form>
</p>

<div style="margin-top: 10px; text-align: right">
<form>
<span id="issuesFromTo">
<span id="pagination"></span>
<input type="button" id="prevbutton" value="Prev" onclick="updatePage(istart - perpage);" disabled="true">
<input type="button" value="Next" onclick="updatePage(istart + perpage);" id="nextbutton">
</form>
</div>

<!---<form name="listing" action="project_view.cfm?id=#project.getID()#" method="post">--->
<form action="#root#page.viewissues&id=#project.getId()#" method="post" name="projectform">
<div id="issues">
	<div class="ready">
	<p>
	<table id="listing" cellspacing="0">
		<tr class="hdRow">
			<td><a href="javaScript:sortData('publicid')" class="adminListHeaderTD">ID</a></td>
			<td><a href="javaScript:sortData('name')" class="adminListHeaderTD">Name</a></td>
			<td><a href="javaScript:sortData('issuetype')" class="adminListHeaderTD">Type</a></td>
			<td><a href="javaScript:sortData('locusname')" class="adminListHeaderTD">Area</a></td>
			<td><a href="javaScript:sortData('severityrank')" class="adminListHeaderTD">Severity</a></td>
			<td><a href="javaScript:sortData('statusrank')" class="adminListHeaderTD">Status</a></td>
			<td><a href="javaScript:sortData('username')" class="adminListHeaderTD">Owner</a></td>
			<td><a href="javaScript:sortData('prettyduedate')" class="adminListHeaderTD">Due</a></td>
			<td><a href="javaScript:sortData('prettydate')" class="adminListHeaderTD">Updated</a></td>
		</tr>
		<tbody id="datadisplay">
		</tbody>
	</table>
	</p>
	</div>
</div>
	
<br />

<!--- A field that stores all issues in set, not page, but all in current set --->
<input type="hidden" name="forprint" id="forprint">	

<p align="right">
<!---<input type="submit" name="printAll" id="printAll" value="Print Issues" onClick="return checkprint()" class="button blue" />--->
<input type="button" name="add" value="Add Issue" class="button blue" onClick="document.location.href='#root#page.viewissue&id=0&pid=#project.getID()#'">
</p>
	
</cfoutput>

<div id="newFilterForm" style="display:none" title="Save Filter">
<form>
Enter a name for your filter:
<input id="newFilterName">
</form>
</div>