<cfcomponent output="false" displayName="User Gateway">

	<cfset variables.dsn = "">
	<cfset variables.username = "">
	<cfset variables.password = "">
	<cfset variables.plaintextpassword = "no">
	<cfset variables.lockname = "LighthousePro_UserDAO">
	
	<cffunction name="init" access="public" returnType="UserGateway" output="false">
		<cfargument name="settings" type="any" required="true">
	
		<cfset variables.config = arguments.settings.getConfig()>	
		<cfset variables.dsn = variables.config.dsn>
		<cfset variables.username = variables.config.username /> 
		<cfset variables.password = variables.config.password />
		<cfset variables.plaintextpassword = variables.config.plaintextpassword>
	
		<cfreturn this>
	</cffunction>	

	<cffunction name="deleteFilter" access="public" returnType="void" output="false">
		<cfargument name="user" type="any" required="true">
		<cfargument name="id" type="uuid" required="true">

		<cfquery datasource="#variables.dsn#" username="#variables.username#" password="#variables.password#">
		delete from lh_filters
		where useridfk = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.user.getId()#" maxlength="35">
		and id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.id#" maxlength="35">
		</cfquery>
	</cffunction>

	<cffunction name="deleteUser" access="public" returnType="void" output="false">
		<cfargument name="id" type="uuid" required="true">

		<cfquery datasource="#variables.dsn#" username="#variables.username#" password="#variables.password#">
		delete from lh_users
		where id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.id#" maxlength="35">
		</cfquery>
			
		<!--- clean up groups --->
		<cfquery datasource="#variables.dsn#" username="#variables.username#" password="#variables.password#">
		delete from lh_users_groups
		where useridfk = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.id#" maxlength="35">
		</cfquery>
		
		<!--- remove me from projects --->
		<cfquery datasource="#variables.dsn#" username="#variables.username#" password="#variables.password#">
		delete from lh_projects_users
		where useridfk = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.id#" maxlength="35">
		</cfquery>
		
		<cfquery datasource="#variables.dsn#" username="#variables.username#" password="#variables.password#">
		delete from lh_projects_users_email
		where useridfk = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.id#" maxlength="35">
		</cfquery>
			
	</cffunction>

	<cffunction name="getFilterForUser" access="public" returnType="query" output="false">
		<cfargument name="userid" type="any" required="true">
		<cfargument name="filterid" type="any" required="true">

		<cfset var data = "">
		
		<cfquery name="data" datasource="#variables.dsn#" username="#variables.username#" password="#variables.password#">
		select	id, projectidfk, issuetypeidfk, projectlocusidfk, severityidfk, statusidfk, assigneduseridfk, resultcount, milestoneidfk, keywordfilter, name
		from	lh_filters
		where	useridfk = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userid#">
		and		id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filterid#">
		</cfquery>
		
		<cfreturn data>
	</cffunction>

	<cffunction name="getFiltersForUser" access="public" returnType="query" output="false"
				hint="Gets the filters for a user.">		
		<cfargument name="id" type="uuid" required="true">
		<cfset var data = "">
		
		<cfquery name="data" datasource="#variables.dsn#" username="#variables.username#" password="#variables.password#">
		select	id, projectidfk, issuetypeidfk, projectlocusidfk, severityidfk, statusidfk, assigneduseridfk, resultcount, milestoneidfk, keywordfilter, name
		from	lh_filters
		where	useridfk = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.id#">
		order by name asc
		</cfquery>
		
		<cfreturn data>
	</cffunction>
		
	<cffunction name="getGroupsForUser" access="public" returnType="string" output="false"
				hint="Gets the groups for a user.">		
		<cfargument name="id" type="uuid" required="true">
		<cfset var data = "">
		
		<cfquery name="data" datasource="#variables.dsn#" username="#variables.username#" password="#variables.password#">
			select 	lh_groups.name
			from	lh_groups, 
					lh_users_groups
			where	lh_users_groups.useridfk = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.id#" maxlength="35">
			and		lh_users_groups.groupidfk = lh_groups.id
		</cfquery>
		
		<cfreturn valueList(data.name)>
	</cffunction>

	<cffunction name="getUsers" access="public" returnType="query" output="false"
				hint="Gets all the users.">		
		
		<cfset var data = "">
		
		<cfquery name="data" datasource="#variables.dsn#" username="#variables.username#" password="#variables.password#">
			select 	id, username, emailaddress, password, name
			from	lh_users
		</cfquery>
		
		<cfreturn data>
	</cffunction>

	<cffunction name="newUser" access="public" returnType="UserBean" output="false">
		<cfset var bean = createObject("component","UserBean")>		
		<cfset bean.setConfig(variables.config)>
		<cfreturn bean>
	</cffunction>
	
	<cffunction name="read" access="public" returnType="UserBean" output="false">
		<cfargument name="id" type="uuid" required="true">
		<cfset var uBean = createObject("component","UserBean")>
		<cfset var getit = "">
		
		<cfset uBean.setConfig(variables.config)>

		<cfquery name="getit" datasource="#variables.dsn#" username="#variables.username#" password="#variables.password#">
			select 	id, username, emailaddress, password, name
			from	lh_users
			where	id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.id#" maxlength="35">
		</cfquery>
		
		<cfif getit.recordCount>
			<cfset uBean.setID(getit.id)>
			<cfset uBean.setUserName(getit.username)>
			<cfset uBean.setEmailAddress(getit.emailaddress)>
			<cfset uBean.setPassword(getit.password)>
			<cfset uBean.setName(getit.name)>
			<cfset uBean.setRoles(getGroupsForUser(getit.id))>
			<!---
			Why do I do this? If we don't initialize the projects, when we save prefs, our projects is blank.
			TODO: Rethink this. I could just call the gets and ignore the result
			--->
			<cfset uBean.getProjects()>
			<cfset uBean.getEmailProjects()>
		</cfif>
		<cfreturn uBean>
	</cffunction>

	<cffunction name="readByUsername" access="public" returnType="UserBean" output="false">
		<cfargument name="username" type="string" required="true">
		<cfset var getit = "">
		
		<cfquery name="getit" datasource="#variables.dsn#" username="#variables.username#" password="#variables.password#">
			select 	id, username, emailaddress, password, name
			from	lh_users
			where	username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.username#">
		</cfquery>
		
		<cfif getit.recordCount is 1>
			<cfreturn read(getit.id)>
		<cfelse>
			<cfthrow message="Invalid username.">
		</cfif>
		
	</cffunction>		

	<cffunction name="saveFilter" access="public" returnType="void" output="false">
		<cfargument name="user" type="any" required="true">
		<cfargument name="filter" type="struct" required="true">
		<cfset var existingFilters = "">
		<cfset var checkExisting = "">
			
		<!--- Single thread per user --->
		<cflock name="#variables.lockname#_#arguments.user.getId()#" type="exclusive" timeout="30">
			<cfset existingFilters = getFiltersForUser(arguments.user.getID())>
			<cfquery name="checkExisting" dbtype="query">
			select	id
			from	existingFilters
			where	name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filter.name#">
			</cfquery>
			
			<cfif checkExisting.recordCount>
				<cfquery datasource="#variables.dsn#" username="#variables.username#" password="#variables.password#">
				update lh_filters
				set useridfk = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.user.getID()#" maxlength="35">,
				projectidfk =  <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filter.projectid#" maxlength="35">,
				issuetypeidfk =  <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filter.issuetype#" maxlength="35">,
				projectlocusidfk = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filter.locus#" maxlength="35">,
				severityidfk =  <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filter.severity#" maxlength="35">,
				statusidfk =  <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filter.status#" maxlength="35">,
				assigneduseridfk =  <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filter.owner#" maxlength="35">,
				keywordfilter =  <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filter.keyword#" maxlength="255">,
				milestoneidfk =  <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filter.milestone#" maxlength="35">,
				resultcount =  <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filter.perpage#">,
				where id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#checkExisting.id#" maxlength="35">
				</cfquery>				
			<cfelse>
				<cfquery datasource="#variables.dsn#" username="#variables.username#" password="#variables.password#">
				insert into lh_filters(useridfk,projectidfk,issuetypeidfk,projectlocusidfk,severityidfk,statusidfk,assigneduseridfk,resultcount,milestoneidfk,keywordfilter,name,id)
				values(
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.user.getID()#" maxlength="35">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filter.projectid#" maxlength="35">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filter.issuetype#" maxlength="35">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filter.locus#" maxlength="35">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filter.severity#" maxlength="35">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filter.status#" maxlength="35">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filter.owner#" maxlength="35">,
				<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filter.perpage#">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filter.milestone#" maxlength="35">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filter.keyword#" maxlength="255">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filter.name#" maxlength="255">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#createUUID()#" maxlength="35">				
				)
				</cfquery>

			</cfif>
		</cflock>

	</cffunction>

	<cffunction name="saveUser" access="public" returnType="void" output="false">
		<cfargument name="bean" type="any" required="true">
		<cfset var newID = "">
		<cfset var id = "">
		<cfset var checkDupe = "">
		<cfset var old = "">
		<cfset var i = "">
		<cfset var roles = "">
		<cfset var r = "">
		<cfset var getrole = "">
		
		<cfif len(bean.getId()) and bean.getId() neq 0>

			<cflock name="#variables.lockname#" type="exclusive" timeout="30">
				<cfquery name="checkDupe" datasource="#variables.dsn#" username="#variables.username#" password="#variables.password#">
					select 	username
					from	lh_users
					where	username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.bean.getUserName()#" maxlength="50">
					and		id <> <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.bean.getID()#" maxlength="35">
				</cfquery>
				
				<cfif checkDupe.recordCount>
					<cfthrow type="UserDAO.DuplicateUser" message="Cannot insert two users with the same username.">
				</cfif>
	
				<cfset old = read(bean.getID())>
				
				<cfquery datasource="#variables.dsn#" username="#variables.username#" password="#variables.password#">
				update lh_users
				set username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.bean.getUserName()#" maxlength="50">,
				emailaddress = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.bean.getEmailAddress()#" maxlength="50">,
				<cfif old.getPassword() neq bean.getPassword()>
				password = 
						<cfif variables.plaintextpassword>
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.bean.getPassword()#" maxlength="50">,
						<cfelse>
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#hash(arguments.bean.getPassword(),"SHA")#" maxlength="50">,
						</cfif>
				</cfif>
				name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.bean.getName()#" maxlength="50">
				where id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.bean.getID()#" maxlength="35">
				</cfquery>
			
			</cflock>
				
		<cfelse>

			<cfset newID = createUUID()>

			<cflock name="#variables.lockname#" type="exclusive" timeout="30">
				<cfquery name="checkDupe" datasource="#variables.dsn#" username="#variables.username#" password="#variables.password#">
					select 	username
					from	lh_users
					where	username = 	<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.bean.getUserName()#" maxlength="50">
				</cfquery>
				
				<cfif checkDupe.recordCount>
					<cfthrow type="UserDAO.DuplicateUser" message="Cannot insert two users with the same username.">
				</cfif>
				
				<cfquery datasource="#variables.dsn#" username="#variables.username#" password="#variables.password#">
					insert into lh_users(id,username,emailaddress,password,name)
					values(
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#newid#" maxlength="35">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.bean.getUserName()#" maxlength="50">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.bean.getEmailAddress()#" maxlength="50">,
						<cfif variables.plaintextpassword>
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.bean.getPassword()#" maxlength="50">,
						<cfelse>
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#hash(arguments.bean.getPassword(),"SHA")#" maxlength="50">,
						</cfif>
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.bean.getName()#" maxlength="50">
						)
				</cfquery>
				
				<cfset bean.setID(newid)>
			</cflock>
		
		</cfif>

		<!--- handle projects, email projects --->
		<cfquery datasource="#variables.dsn#" username="#variables.username#" password="#variables.password#">
		delete from lh_projects_users
		where useridfk = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.bean.getId()#" maxlength="35">
		</cfquery>
		<cfloop index="i" list="#arguments.bean.getProjects()#">
			<cfquery datasource="#variables.dsn#" username="#variables.username#" password="#variables.password#">
			insert into lh_projects_users(projectidfk, useridfk)
			values(<cfqueryparam cfsqltype="cf_sql_varchar" value="#i#" maxlength="35">,<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.bean.getId()#" maxlength="35">)
			</cfquery>
		</cfloop>

		<cfquery datasource="#variables.dsn#" username="#variables.username#" password="#variables.password#">
		delete from lh_projects_users_email
		where useridfk = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.bean.getId()#" maxlength="35">
		</cfquery>				

		<cfloop index="i" list="#arguments.bean.getEmailProjects()#">
			<cfquery datasource="#variables.dsn#" username="#variables.username#" password="#variables.password#">
			insert into lh_projects_users_email(projectidfk, useridfk)
			values(<cfqueryparam cfsqltype="cf_sql_varchar" value="#i#" maxlength="35">,<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.bean.getId()#" maxlength="35">)
			</cfquery>
		</cfloop>
				
		<!--- persist groups --->
		<!---- Hack alert. check roles, and for each role, get the ID and assign. --->
		<cfquery datasource="#variables.dsn#" username="#variables.username#" password="#variables.password#">
		delete from lh_users_groups
		where useridfk = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.bean.getId()#" maxlength="35">
		</cfquery>	

		<cfset roles = arguments.bean.getRoles()>
		<cfif len(roles)>
			<cfloop index="r" list="#roles#">
			
				<cfquery name="getrole" datasource="#variables.dsn#" username="#variables.username#" password="#variables.password#">
				select	id
				from	lh_groups
				where	name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#r#">
				</cfquery>
				
				<cfif getrole.recordCount>
					<cfquery datasource="#variables.dsn#" username="#variables.username#" password="#variables.password#">
					insert into lh_users_groups(groupidfk, useridfk)
					values(<cfqueryparam cfsqltype="cf_sql_varchar" value="#getRole.id#" maxlength="35">,<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.bean.getId()#" maxlength="35">)
					</cfquery>
				</cfif>
				
			</cfloop>
		</cfif>
											
	</cffunction>		


</cfcomponent>