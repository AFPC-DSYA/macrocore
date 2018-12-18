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
  @copyright:  None - Public domain

  @example:
    %mm_deleteUsers(profiles_full)

**/

%macro mm_deleteUsers(inputds,outputds=_null_,firstname=firstname,lastname=lastname,dodid=gigid);
    data &outputds.;
        length personuri groupuri emailuri locationuri $256;
        length name_space _personName $60.;
        call missing(personuri,groupuri,emailuri,locationuri,_personName);
        set &inputds.;
        where &dodid. ne "&sysuserid.";
        name_space = strip(strip(&lastname.)||' '||strip(&firstname.));
        /* validate inputs with regular expressions */
        /* dodId must be 10 digits followed by 1 letter only */
        if not prxmatch('/^\d{10}\w{1}$/',strip(&dodid.)) then do;
            * invalid dodID;
            put 'ERROR: User: ' &dodid. ' with Name: ' name_space ' has invalid dodID. Not deleting.';
            delete;            
        end;
        /*find and delete users by userid/dodID*/
        personuri = "omsobj:Person?Person[Logins/Login[@UserID='"||strip(&dodid.)||"']]";
        /* remove location associations without deleting objects */
        getPersonFlag = metadata_getattr(personuri,"Name",_personName);
        if getPersonFlag = 0 then do;
            *removing location mutates list of associates, so always read first and 
             delete first (getnasn returns number of associations);
            do while (metadata_getnasn(personuri,"Locations",1,locationuri) > 0);
                locDelFlag=metadata_setassn(personuri,"Locations","Remove",locationuri);
            end;
        end;
        /* delete user */
        personDelFlag=metadata_delobj(personuri);
        if personDelFlag = 0 then put 'NOTE: User: ' &dodid. ' with Name: ' name_space ' successfully deleted.';
        else if personDelFlag = -2 then put 'ERROR: User: ' &dodid. ' with Name: ' name_space ' could not be deleted.';
        else if personDelFlag = -3 then put 'WARNING: User: ' &dodid. ' with Name: ' name_space ' not found.';
        else put 'ERROR: Unable to connect to metadata server.'; 
    run;
%mend;
