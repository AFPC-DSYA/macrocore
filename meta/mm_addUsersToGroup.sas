/**
  @file: mm_addUsersToGroup.sas
  @brief: adds metadata users to a group
  @details: given a dataset of users with userIds that 
             are already in metadata, assigns users to specified group

  @param groupname: string for name of group in metadata
  @param inputds: name of input dataset containing users to be added to 
                  group
    @required columns: dodId/edipi (10 digit + 1 letter)
  @param dodId=: name of column contain dodId/edipi (10 digit + 1 letter)
  @param outputds=: name of output dataset containing flags

  @returns outputds:  dataset containing flags for addition of users to group

  @version: SAS 9.4
  @author: Caleb Ziegler
  @copyright: None - Public domain

  @example:
    %mm_addUsersToGroup(TestGroup1,peopleSsnToDODid,dodId=gigid);

**/


%macro mm_addUsersToGroup(groupname,inputds,dodId=gigid,outputds=_null_);
    data &outputds.;
        length groupuri peopleuri $256;
        call missing(groupuri,peopleuri);
        set &inputds.;
        groupuri = "omsobj:IdentityGroup?@Name='&groupname.'";
        peopleuri = "omsobj:Person?Person[Logins/Login[@UserID='"||strip(&dodId.)||"']]";
        addGroupFlag=metadata_setassn(groupuri,"MemberIdentities","Append",peopleuri);
        if addGroupFlag=0 then put 'NOTE: User: ' &dodId. ' added to Group: ' "&groupname.";
        else if addGroupFlag=-3 then put 'WARNING: Group: ' "&groupname." ' not found.';
        else if addGroupFlag=-6 then put 'WARNING: User: ' &dodid. ' not found.'; 
        else put 'ERROR: User: ' &dodId. ' not added to Group: ' "&groupname." ' due to errors.';
    run;
%mend;
