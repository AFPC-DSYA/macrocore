/**
  @file: mm_addUserToGroup.sas
  @brief: adds one metadata user to a group
  @details: given one userId that is already in metadata, 
            assigns user to specified group

  @param groupname: string for name of group in metadata
  @param dodId=: column name for dodId/edipi (10 digit + 1 letter)

  @returns columns: _groupuri, _personuri, _groupStatus, addGroupFlag

  @version: SAS 9.4
  @author: Caleb Ziegler
  @copyright: None - Public domain

  @example:
    data output;
        set input;
        ...
        %mm_addUserToGroup(TestGroup1,dodId=gigid);
        ...
    run;

**/

%macro mm_addUserToGroup(groupname,dodId=gigid);
    /* add length statements to parent calling macro
    length _groupuri _personuri $256;
    length _groupStatus $6;
    call missing(_groupuri,_personuri);
    */
    _groupStatus = "add";
    _groupuri = "omsobj:IdentityGroup?@Name='&groupname.'";
    _personuri = "omsobj:Person?Person[Logins/Login[@UserID='"||strip(&dodId.)||"']]";
    addGroupFlag=metadata_setassn(_personuri,"IdentityGroups","Append",_groupuri);
/*    if addGroupFlag=0 then put 'NOTE: User: ' strip(&dodId.) ' added to Group ' "&groupname.";*/
/*    else if addGroupFlag=-3 then put 'ERROR: User: ' strip(&dodId.) ' not found. Not adding user to Group: ' "&groupname."; */
/*    else if addGroupFlag=-6 then put 'ERROR: Group: ' "&groupname." ' not found. Not adding User: ' strip(&dodId.) ' to group.'; */
/*    else put 'ERROR: User: ' strip(&dodId.) ' not added to Group: ' "&groupname." ' due to errors.';*/
%mend;

