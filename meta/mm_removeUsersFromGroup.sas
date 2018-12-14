/**
  @file: mm_removeUsersFromGroup.sas
  @brief: removes metadata users from a group
  @details: given a dataset of users with userIds that 
             are already in metadata, removes users from specified group

  @param groupname: string for name of group in metadata
  @param inputds: name of input dataset containing users to be removed  
                  from group
    @required columns: dodId/edipi (10 digit + 1 letter)
  @param dodId=: name of column contain dodId/edipi (10 digit + 1 letter)
  @param outputds=: name of output dataset containing flags

  @returns outputds: dataset containing flags for removal of users from group

  @version: SAS 9.4
  @author: Caleb Ziegler
  @copyright:  None - Public domain

  @example:
    %mm_removeUsersFromGroup(TestGroup1,peopleSsnToDODid,dodId=gigid);

**/

%macro mm_removeUsersFromGroup(groupname,inputds,dodId=gigid,outputds=_null_);
data &outputds.;
    length groupuri peopleuri $256;
    set &inputds.;
    groupuri = "omsobj:IdentityGroup?@Name='&groupname.'";
    peopleuri = "omsobj:Person?Person[Logins/Login[@UserID='"||strip(&dodId.)||"']]";
    removeGroupFlag=metadata_setassn(groupuri,"MemberIdentities","Remove",peopleuri);
    if removeGroupFlag=0 then put 'NOTE: User: ' &dodId. ' removed from Group ' "&groupname.";
    else if removeGroupFlag=-3 then put 'WARNING: User: ' &dodid. ' not found.'; 
    else put 'ERROR: User: ' &dodId. ' not removed from Group ' "&groupname." ' due to errors.';    
run;
%mend;
