/**
  @file: mm_createGroup.sas
  @brief: Creates a metadata group
  @details: assigns properties to new metadata group and returns dataset
             with flags denoting success of various steps 

  @param groupname: string for name of group in metadata
  @param displayname: string for displayname property of group in metadata
  @param description: string for description property of group
  @param outputds=: name of output dataset containing flags

  @returns outputds:  dataset containing flags for creation of group

  @version: SAS 9.4
  @author: Caleb Ziegler
  @copyright: None - Public domain

  @example:
    %mm_createGroup(TestGroup1, TestGroup1, Another Group for testing);
    %mm_createGroup(TestGroup1, TestGroup1, Another Group for testing, outputds=test_dataset);

**/

%macro mm_createGroup(groupname, displayname, description, outputds=_null_);
    data &outputds.;
        length groupuri $256;
        length _groupname $100;
        call missing(groupuri,_groupname);
        getGroupFlag=metadata_getattr("omsobj:IdentityGroup?@Name='&groupname.'","Name",_groupname);
        if getGroupFlag = 0 then do;
            put 'WARNING: Group: ' "&groupname." ' already exists. Terminating.';
            delete;
        end; 
        newGroupFlag=metadata_newobj("IdentityGroup",groupuri,"&groupname.");
        publicFlag=metadata_setattr(groupuri,"PublicType","UserGroup");
        usageFlag=metadata_setattr(groupuri,"UsageVersion","1000000.0");
        descFlag=metadata_setattr(groupuri,"Desc","&description.");
        displayFlag=metadata_setattr(groupuri,"DisplayName","&displayname.");
        if sum(newGroupFlag,publicFlag,usageFlag,descFlag,displayFlag) = 0 then put 'NOTE: Group ' "&groupname." ' successfully created.';
        else if newGroupFlag ne 0 then put 'ERROR: Group ' "&groupname." ' not created due to errors.';
        else put 'ERROR: Group ' "&groupname." ' created but has errors.';
    run;
%mend;
