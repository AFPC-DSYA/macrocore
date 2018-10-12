/**
  @file: mm_updateUsers.sas
  @brief: updates information of user accounts in metadata 
  @details: given a dataset of valid users containing firstname, lastname, 
			job title, pascode, email, and dodid, updates user information

  @param inputds: name of input dataset containing users and information
				  for updating those user accounts
	@required columns: firstname, lastname, job/duty title, pascode,
					   email, dodId/edipi (10 digit + 1 letter)
  @param outputds=: name of output dataset containing flags
  @param firstname=: name of column containing first name
  @param lastname=: name of column containing last name
  @param title=: name of column containing job/duty title
  @param pascode=: name of column containing pascode
  @param email=: name of column containing email
  @param dodid=: name of column containing dodId/edipi (10 digit + 1 letter)

  @returns outputds: dataset containing flags for update of users

  @version: SAS 9.4
  @author: Caleb Ziegler
  @copyright: GNU GENERAL PUBLIC LICENSE v3

  @example:
	%mm_updateUsers(profiles_full);

**/

%macro mm_updateUsers(inputds,outputds=work.updated_Users,firstname=firstname,lastname=lastname,
                        title=title,pascode=pascode,email=email,dodid=gigid);
	data &outputds.;
	    length personuri dodIduri locationuri emailuri $256;
		length _location _locationNew emailtype $8;
		length name_underscore name_comma _personName _displayName _title _email _emailname _emailtype $60;
		length _userId $12;
		set &inputds.;
		name_underscore = strip(strip(&lastname.)||"_"||strip(&firstname.));
		name_comma = strip(strip(&lastname.)||", "||strip(&firstname.));
		if prxmatch('/us\.af\.mil/i',&email.) then emailtype='LIFE';
		else if prxmatch('/mail\.mil/i',&email.) then emailtype='PENTAGON';
		else emailtype='WORK';
	    /* find out if user already in STARS (check if login exists for UserID and if person linked to login) */
	    dodIduri = "omsobj:Login?@UserID='"||strip(&dodid.)||"'";
	    userIdGetFlag=metadata_getattr(dodIduri,"UserID",_userId);
		personuri = "omsobj:Person?Person[Logins/Login[@UserID='"||strip(&dodid.)||"']]";
		personGetFlag=metadata_getattr(personuri,"Name",_personName);
	    if (_userId = strip(&dodid.) or userIdGetFlag = 0) and personGetFlag = 0 then do;
			* person exists in STARS, can begin updating;
			* begin updating person details;
			displayGetFlag = metadata_getattr(personuri,"DisplayName",_displayName);
			if displayGetFlag = 0 and upcase(_displayName) ne upcase(strip(name_comma)) then do;
				displaySetFlag = metadata_setattr(personuri,"DisplayName",name_comma);
			end;
			else displaySetFlag = displayGetFlag;
			titleGetFlag = metadata_getattr(personuri,"Title",_title);
			if titleGetFlag = 0 and upcase(_title) ne upcase(strip(title)) then do;
				titleSetFlag = metadata_setattr(personuri,"Title",strip(&title.));
			end;
			else titleSetFlag = titleGetFlag;
			*do location next - many people can be assigned to each location;
			k = 1;
			do while (metadata_getnasn(personuri,"Locations",k,locationuri) > 0);
				call missing (_location);
				locationGetFlag = metadata_getattr(locationuri,"Name",_location); 
				if locationGetFlag = 0 and _location ne strip(&pascode.) then do;
					*break association to location ;
					locationSetFlag = metadata_setassn(personuri,"Locations","Remove",locationuri);
					/* associate new pascode to person (create new pascode if no pascode in system) */
					locationuri="omsobj:Location?@Name='"||strip(&pascode.)||"'";
					locationGetFlag=metadata_getattr(locationuri,"Name",_locationNew);
					if locationGetFlag < 0 then do;
						*we have to create a location and associate it to person;
						locationSetFlag=metadata_newobj("Location",locationuri,strip(&pascode.),"Foundation",personuri,"Locations");
						locationTypeSetFlag=metadata_setattr(locationuri,"LocationType","PASCODE");
						locationUsageFlag=metadata_setattr(locationuri,"UsageVersion","1000000.0");
						locationAreaFlag=metadata_setattr(locationuri,"Area",strip(&pascode.));
					end;
					else do;
						*location already created, just set association for person;
						locationSetFlag=metadata_setassn(personuri,"Locations","Append",locationuri);
					end;
				end;
				else locationSetFlag = locationGetFlag;
				k+1;
			end;
			if k = 1 then do;
				/* associate new pascode to person (create new pascode if no pascode in system) */
				locationuri="omsobj:Location?@Name='"||strip(&pascode.)||"'";
				locationGetFlag=metadata_getattr(locationuri,"Name",_locationNew);
				if locationGetFlag < 0 then do;
					*we have to create a location and associate it to person;
					locationSetFlag=metadata_newobj("Location",locationuri,strip(&pascode.),"Foundation",personuri,"Locations");
					locationTypeSetFlag=metadata_setattr(locationuri,"LocationType","PASCODE");
					locationUsageFlag=metadata_setattr(locationuri,"UsageVersion","1000000.0");
					locationAreaFlag=metadata_setattr(locationuri,"Area",strip(&pascode.));
				end;
				else do;
					*location already created, just set association for person;
					locationSetFlag=metadata_setassn(personuri,"Locations","Append",locationuri);
				end;
			end;
			*finally, email -
				note: typically each email only assigned to one person, but sometimes one email may be used
					  by two different accounts (think reserve/civilian), also, people can have mult. emails ;
			j = 1;
			do while (metadata_getnasn(personuri,"EmailAddresses",j,emailuri) > 0);
				call missing (_email);
				emailTypeGetFlag = metadata_getattr(emailuri,"EmailType",_emailtype);
				emailNameGetFlag = metadata_getattr(emailuri,"Name",_emailname);
				emailGetFlag = metadata_getattr(emailuri,"Address",_email); 
				if sum(emailTypeGetFlag,emailNameGetFlag,emailGetFlag) = 0 
					and upcase(_email) ne upcase(strip(&email.)) and upcase(_emailtype) = upcase(strip(emailtype)) then do;
					emailSetFlag = metadata_setattr(emailuri,"Address",strip(&email.));
				end;
				else if sum(emailTypeGetFlag,emailNameGetFlag,emailGetFlag) = 0 
					and upcase(_email) = upcase(strip(&email.)) and upcase(_emailtype) ne upcase(strip(emailtype)) then do;
					emailTypeSetFlag = metadata_setattr(emailuri,"EmailType",strip(emailtype));
					emailNameSetFlag = metadata_setattr(emailuri,"Name",strip(emailtype));
				end;
				else do;
					emailTypeSetFlag = emailTypeGetFlag;
					emailNameSetFlag = emailNameGetFlag;
					emailSetFlag = emailGetFlag;
				end;
				j+1;
			end;
			if j = 1 then do;
				*create email and associate to person - we never entered do loop;
				emailuri="omsobj:Email?@Address='"||strip(&email.)||"'";
				emailGetFlag=metadata_getattr(emailuri,"Address",_email);
				if emailGetFlag < 0 then do;
					*we have to create a new email and assign it to person;
					emailNameSetFlag=metadata_newobj("Email",emailuri,strip(emailtype),"Foundation",personuri,"EmailAddresses");
					emailSetFlag=metadata_setattr(emailuri,"Address",strip(&email.));
					emailTypeSetFlag=metadata_setattr(emailuri,"EmailType",strip(emailtype));
					emailUsageFlag=metadata_setattr(emailuri,"UsageVersion","0.0");
				end;
				else do;
					*email aready created, just set association for person;
					emailSetFlag=metadata_setassn(personuri,"EmailAddresses","Append",emailuri);
				end;	
			end;
			else do;
				emailUsageFlag = 0;
			end;
			*log status of update;
			if sum(displaySetFlag,titleSetFlag,locationSetFlag,emailSetFlag,emailTypeSetFlag,
					emailNameSetFlag,emailUsageFlag,emailAssignFlag) = 0 then
				put 'NOTE: User: ' &dodid. ' updated successfully.';
			else put 'ERROR: Errors when updating User: ' &dodid.; 
		end;
		else do;
			put 'WARNING: User: ' &dodid. ' not found in STARS.';
			delete;
		end;
	run;
%mend;
