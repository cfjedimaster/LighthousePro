<cfcomponent output="false" hint="Handles User related issues." extends="ModelGlue.gesture.controller.Controller" beans="applicationSettings,userService">

	<cffunction name="init" access="public" output="false" hint="Constructor">
		<cfargument name="framework" />
		
		<cfset super.init(framework) />
		
		<cfreturn this />
	</cffunction>

	<cffunction name="checkAdmin" access="public" output="false">
		<cfargument name="event" type="any" required="true">
		<cfset var eventlist = arguments.event.getArgument("events")>
		<cfset var me = arguments.event.getValue("currentUser")>
		<cfset var thisEvent = arguments.event.getValue(arguments.event.getValue("eventValue"))>
		<cfset var e = "">
		
		<!--- If I'm an admin, leave right away --->
		<cfif me.hasRole("admin")>
			<cfreturn>
		</cfif>

		<!--- ok, so loop through eventlist, and if match, its an event we need to secure, since we got here, it means we aren't an admin --->
		<cfloop index="e" list="#eventlist#">
			<cfif findNoCase(e, thisEvent)>
				<cfset arguments.event.addResult("notAuthorized")>
			</cfif>
		</cfloop>
				
	</cffunction>
			
	<cffunction name="checkLogin" access="public" output="false">
		<cfargument name="event" type="any" required="true">
		<cfset var auth = arguments.event.getValue("auth")>
		<cfset var username = "">
		<cfset var password = "">
		<cfset var settings = "">
		<cfset var reqData = "">
		
		<!--- handle auto login via rss --->
		<cfif len(auth)>	
			<cfset settings = beans.applicationSettings.getConfig()>
			<cfset auth = decrypt(auth, settings.secretkey)>
			<cfset username = listLast(listFirst(auth, "&"),"=")>
			<cfset password = listLast(listLast(auth, "&"),"=")>
			<cfif beans.userService.authenticate(username,password)>
				<cfset storeUser(beans.userService.getUserByUsername(username))>
				<cfset arguments.event.setValue("currentuser", getCurrentUser())>				
			</cfif>
		</cfif>
		
		<cfif not loggedIn()>
			<cfset reqData = getHTTPRequestData()>
			<cfif structKeyExists(reqData.headers,"X-Requested-With") and reqData.headers["X-Requested-With"] eq "XMLHttpRequest">
				<cfthrow message="SessionTimeout">
			<cfelse>
				<!--- store what we had wanted --->
				<cfset arguments.event.setValue("desiredurl", cgi.query_string)>
				<cfset arguments.event.addResult("needLogin")>
			</cfif>
		</cfif>

	</cffunction>

	<cffunction name="clearFilters" access="private" output="false">
		<cfif structKeyExists(session, "user") and structKeyExists(session, "filters")>
			<cfset structDelete(session, "filters")>
		</cfif>
	</cffunction>
	
	<cffunction name="clearUser" access="private" output="false">
		<cfset structDelete(session, "user")>
	</cffunction>

	<cffunction name="getCurrentUser" access="private" output="false">
		<cfreturn session.user>
	</cffunction>

	<cffunction name="deleteFilter" access="public" output="false">
		<cfargument name="event" type="any">
		<cfset var me = arguments.event.getValue("currentUser")>
		<cfset var filter = arguments.event.getValue("id")>
		<cfset beans.userService.deleteFilter(me, id)>
	</cffunction>
	
	<cffunction name="deleteUser" access="public" output="false">
		<cfargument name="event" type="any">
		<cfset var markedtodie = arguments.event.getValue("markbox")>
		<cfset beans.userService.deleteUsers(markedtodie)>
	</cffunction>
	
	<!--- This is used for the view layer drop downs --->
	<cffunction name="getCurrentFilters" access="private" output="false" returnType="struct">
		<cfif not structKeyExists(session, "user")>
			<cfthrow message="Unauthenticated call to getCurrentFilters">
		</cfif>
		<cfif not structKeyExists(session, "filters")>
			<cfset session.filters = structNew()>
			<cfset session.filters.issuetype_filter="">
			<cfset session.filters.loci_filter="">
			<cfset session.filters.severity_filter="">
			<cfset session.filters.status_filter="">
			<cfset session.filters.owner_filter="">
			<cfset session.filters.perpage_filter="10">
			<cfset session.filters.milestone_filter="">
			<cfset session.filters.keyword_filter="">
		</cfif>
		<cfreturn session.filters>
	</cffunction>

	<cffunction name="getFilter" access="public" output="false">
		<cfargument name="event" type="any">
		<cfset var user = arguments.event.getValue("currentUser")>
		<cfset var filterid = arguments.event.getValue("id")>
		<cfset var filter = beans.userService.getFilterForUser(user,filterid)>
		<!--- todo, nicer error handling --->
		<cfset session.filters = {}>
		<cfset session.filters.issuetype_filter = filter.issuetypeidfk>
		<cfset session.filters.loci_filter = filter.projectlocusidfk>
		<cfset session.filters.severity_filter = filter.severityidfk>
		<cfset session.filters.status_filter = filter.statusidfk>
		<cfset session.filters.owner_filter = filter.assigneduseridfk>
		<cfset session.filters.milestone_filter = filter.milestoneidfk>
		<cfset session.filters.keyword_filter = filter.keywordfilter>
		<cfset session.filters.perpage_filter = filter.resultcount>
		<cfset arguments.event.setValue("id", filter.projectidfk)>
		
		<cfset arguments.event.forward("page.viewissues","id")>
				
	</cffunction>
	
	<!--- This gets our stored filters --->
	<cffunction name="getStoredFilters" access="public" output="false">
		<cfargument name="event" type="any">
		<cfset user = arguments.event.getValue("currentUser")>
		<cfset arguments.event.setValue("filters",beans.userService.getFiltersForUser(user))>
	</cffunction>
	
	<cffunction name="getUser" access="public" output="false">
		<cfargument name="event" type="any">	
		<cfset var id = arguments.event.getValue("id")>			
		<cfset arguments.event.setValue("user", beans.userService.getUser(id))>
	</cffunction>	
	
	<cffunction name="getUsers" access="public" output="false">
		<cfargument name="event" type="any">		
		<cfset arguments.event.setValue("users", beans.userService.getUsers())>
	</cffunction>	

	<cffunction name="loggedIn" access="private" output="false" hint="Private function to check to see if we are logged in.">
		<cfreturn structKeyExists(session, "user")>
	</cffunction>

	<cffunction name="onRequestStart" access="public" output="false">
		<cfargument name="event" type="any">
		
		<!--- copy settings to the Event scope so we can use it all the time. --->
		<cfif loggedIn()>
			<cfset arguments.event.setValue("currentuser", getCurrentUser())>
			<!--- Add support for defaulting filters for our issues. --->
			<cfif arguments.event.valueExists("clearfilter")>
				<cfset clearFilters()>
			</cfif>
			<cfset arguments.event.setValue("currentfilters", getCurrentFilters())>
		</cfif>
		
	</cffunction>

	<cffunction name="persistFilters" access="public" output="false">
		<cfargument name="event" type="any">
		<cfset var f = structNew()>
		
		<cfset f.issuetype_filter = arguments.event.getValue("issuetype")>
		<cfset f.loci_filter = arguments.event.getValue("locus")>
		<cfset f.severity_filter = arguments.event.getValue("severity")>
		<cfset f.status_filter = arguments.event.getValue("status")>
		<cfset f.owner_filter = arguments.event.getValue("owner")>
		<cfset f.keyword_filter = arguments.event.getValue("keyword")>
		<cfset f.milestone_filter = arguments.event.getValue("milestone")>	
		<cfset f.perpage_filter = arguments.event.getValue("perpage")>
		<cfset session.filters = f>
	</cffunction>
	
	<cffunction name="processLogin" access="public" output="false">
		<cfargument name="event" type="any" required="true">
		<cfset var username = arguments.event.getValue("username")>
		<cfset var password = arguments.event.getValue("password")>
		<cfset var desiredurl = arguments.event.getValue("desiredurl")>
		
		<cfif beans.userService.authenticate(username,password)>
			<cfset storeUser(beans.userService.getUserByUsername(username))>
			<!--- See if we have a desiredurl value - if so, we go there instead of going home --->
			<cfif len(desiredurl)>
				<cflocation url="index.cfm?#desiredurl#" addToken="false">
			</cfif>			
			<cfset arguments.event.addResult("loggedIn")>
		<cfelse>
			<cfset arguments.event.setValue("loginError",1)>
			<cfset arguments.event.addResult("notLoggedIn")>
		</cfif>
		
	</cffunction>

	<cffunction name="processLogout" access="public" output="false">
		<cfargument name="event" type="any" required="true">
		<cfset clearUser()>		
	</cffunction>

	<cffunction name="saveFilter" access="public" output="false">
		<cfargument name="event" type="any">
		<cfset var filter = structNew()>
		<cfset event.copyToScope(filter, "projectid,issuetype,locus,severity,status,owner,keyword,milestone,perpage,name")>
		<cfset beans.userService.saveFilter(arguments.event.getValue("currentuser"),filter)>
	</cffunction>
	
	<cffunction name="savePrefs" access="public" output="false">
		<cfargument name="event" type="any">
		<cfset var me = arguments.event.getValue("currentuser")>
		<!--- Why mydata? To ensure we work with the latest data. Specifically, projects may be out of date. --->
		<cfset var mydata = beans.userService.getUser(me.getId())>
		
		<cfset var cancel = arguments.event.getValue("cancel")>
		<cfset var errors = "">		

		<cfset var password = trim(arguments.event.getValue("password"))>
		<cfset var password2 = trim(arguments.event.getValue("password2"))>
		<cfset var name = htmlEditFormat(trim(arguments.event.getValue("name")))>
		<cfset var emailaddress = htmlEditFormat(trim(arguments.event.getValue("emailaddress")))>
		<cfset var selemailprojects = arguments.event.getValue("selemailprojects","")>

		<cfif cancel is "Cancel">
			<cfset arguments.event.addResult("good")>
		</cfif>

		<cfset mydata.setName(left(name,50))>
		<cfset mydata.setEmailAddress(emailaddress)>
		<cfset mydata.setEmailProjects(selemailprojects)>
				
		<cfset errors = mydata.validate()>
		
		<cfif len(password)>
			<cfif not password2 eq password>
				<cfset arrayAppend(errors, "Your new password and the confirmation did not match.")>
			<cfelse>
				<cfset mydata.setPassword(password)>
			</cfif>
		</cfif>

		<cfif not arrayLen(errors)>
			<cftry>
				<cfset beans.userService.saveUser(mydata)>
				<cfset storeUser(mydata)>
				<cfset arguments.event.setValue("message","Your preferences have been updated.")>
				<cfcatch>
					<cfset errors[1] = cfcatch.message>			
					<cfset arguments.event.setValue("errors", errors)>
					<cfset arguments.event.addResult("bad")>
				</cfcatch>
			</cftry>
		<cfelse>
			<cfset arguments.event.setValue("errors", errors)>
		</cfif>
			
	</cffunction>	
	
	<cffunction name="saveUser" access="public" output="false">
		<cfargument name="event" type="any">
		<cfset var u = arguments.event.getValue("user")>
		<cfset var cancel = arguments.event.getValue("cancel")>
		<cfset var errors = "">		
		<cfset var username = htmlEditFormat(trim(arguments.event.getValue("username")))>
		<cfset var resetpassword = arguments.event.getValue("resetpassword")>
		<cfset var password = trim(arguments.event.getValue("password"))>
		<cfset var name = htmlEditFormat(trim(arguments.event.getValue("name")))>
		<cfset var emailaddress = htmlEditFormat(trim(arguments.event.getValue("emailaddress")))>
		<cfset var selprojects = arguments.event.getValue("selprojects","")>
		<cfset var selemailprojects = arguments.event.getValue("emailprojects","")>
		<cfset var admin = arguments.event.getValue("admin")>
		<cfset var me = getCurrentUser()>
		
		<cfset u.setUserName(left(username,50))>
		<cfif len(resetpassword)>
			<cfset u.setPassword(password)>
		</cfif>
		<cfset u.setName(left(name,50))>
		<cfset u.setEmailAddress(emailaddress)>

		<cfif cancel is "Cancel">
			<cfset arguments.event.addResult("good")>
		</cfif>

		<cfset u.setProjects(selprojects)>
		<cfset u.setEmailProjects(selemailprojects)>
		
		<!--- roles is a bit hackish now --->
		<cfif admin>
			<cfset u.setRoles("admin")>
		<cfelse>
			<cfset u.setRoles("")>
		</cfif>
		
		<cfset errors = u.validate()>
				
		<cfif not arrayLen(errors)>
			<cftry>
				<cfset beans.userService.saveUser(u)>
				<!--- It's possible I edited myself - so if so, update copy --->
				<cfif u.getId() is me.getId()>
					<cfset storeUser(u)>
				</cfif>
				<cfset arguments.event.addResult("good")>
				<cfcatch>
					<cfset errors[1] = cfcatch.message>			
					<cfset arguments.event.setValue("errors", errors)>
					<cfset arguments.event.addResult("bad")>
				</cfcatch>
			</cftry>
		<cfelse>
			<cfset arguments.event.setValue("errors", errors)>
			<cfset arguments.event.addResult("bad")>
		</cfif>
			
	</cffunction>	
		
	<cffunction name="storeUser" access="private" output="false">
		<cfargument name="user" type="any" required="true">
		<cfset session.user = arguments.user>
	</cffunction>
		
</cfcomponent>
	
