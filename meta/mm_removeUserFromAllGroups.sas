/**
  @file: mm_removeUserFromAllGroups.sas
  @brief: remove all groups for one metadata user
  @details: given one userId that is already in metadata, removes user 
            from all groups

  @param dodId=: column name for dodId/edipi (10 digit + 1 letter)

  @returns columns: _groupuri, _personuri, _groupname, _groupStatus, 
                    getGroupNameFlag, removeGroupFlag

  @version: SAS 9.4
  @author: Caleb Ziegler
  @copyright:  None - Public domain

  @example:
    data output;
        set input;
        ...
        %mm_removeUserFromAllGroups(TestGroup1,dodId=gigid);
        ...
    run;

**/

%macro mm_removeUserFromAllGroups(dodId=gigid);
    length _groupuri _personuri $256;
    length _groupname $50;
    length _groupStatus $6;
    call missing(_groupuri,_personuri,_groupname);
    _groupStatus = "remove";
    _personuri = "omsobj:Person?Person[Logins/Login[@UserID='"||strip(&dodId.)||"']]";
    _k = 1; 
    do while (metadata_getnasn(_personuri,"IdentityGroups",k,_groupuri) > 0);
        getGroupNameFlag=metadata_getattr(_groupuri,"Name",_groupname);
        removeGroupFlag=metadata_setassn(_personuri,"IdentityGroups","Remove",_groupuri);
        if removeGroupFlag=0 then put 'NOTE: User: ' strip(&dodId.) ' removed from Group: ' strip(_groupname);
        else if removeGroupFlag=-3 then put 'ERROR: User: ' strip(&dodId.) ' not found. Not removing user from Group: ' strip(_groupname); 
        else if removeGroupFlag=-6 then put 'ERROR: Group: ' strip(_groupname) ' not found. Not removing User: ' strip(&dodId.) ' from group.'; 
        else put 'ERROR: User: ' strip(&dodId.) ' not removed from Group: ' strip(_groupname) ' due to errors.';  
        _k = _k + 1;
    end;  
%mend;

