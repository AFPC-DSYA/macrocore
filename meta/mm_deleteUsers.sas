/**
  @file: mm_deleteUsers.sas
  @brief: deletes Users from metadata 
  @details: given a dataset of people with firstname, lastname, 
			and dodid, deletes those User accounts

  @param inputds: name of input dataset containing users to delete
	@required columns: firstname, lastname, dodId/edipi (10 digit + 1 letter)
  @param outputds=: name of output dataset containing flags
  @param firstname=: name of column containing first name
  @param lastname=: name of column containing last name
  @param dodid=: name of column containing dodId/edipi (10 digit + 1 letter)

  @returns outputds: dataset containing flags for deletion of users

  @version: SAS 9.4
  @author: Caleb Ziegler
  @copyright: GNU GENERAL PUBLIC LICENSE v3

  @example:
	%mm_deleteUsers(profiles_full)

**/

%macro mm_deleteUsers(inputds,outputds=_null_,firstname=firstname,lastname=lastname,dodid=gigid);
    data &outputds.;
        length personuri groupuri emailuri locationuri $256;
        length name_underscore $60.;
        set &inputds.;
        where &dodid. ne "&sysuserid.";
        name_underscore = strip(strip(&lastname.)||'_'||strip(&firstname.));
        /*find and delete users by userid/dodID*/
        personuri = "omsobj:Person?Person[Logins/Login[@UserID='"||strip(&dodid.)||"']]";
		/* remove location associations without deleting objects */
		k = 1;
		do while (metadata_getnasn(personuri,"Locations",k,locationuri) > 0);
			locDelFlag=metadata_setassn(personuri,"Locations","Remove",locationuri);
			k+1;
		end;
		/* delete user */
        personDelFlag=metadata_delobj(personuri);
        if personDelFlag = 0 then put 'NOTE: User: ' name_underscore ' with UserID: ' &dodid. ' successfully deleted.';
        else put 'ERROR: User: ' name_underscore 'with UserId' &dodid. ' not deleted.';
        drop personuri;
    run;
%mend;
