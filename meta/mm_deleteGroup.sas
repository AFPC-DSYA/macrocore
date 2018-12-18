/**
  @file: mm_deleteGroup.sas
  @brief: Deletes a metadata group
  @details: deletes metadata group identified by given name
             and outputs flags in output dataset

  @param groupname: string for name of group in metadata
  @param outputds=: name of output dataset containing flags

  @returns outputds: dataset containing flags for deletion of group

  @version: SAS 9.4
  @author: Caleb Ziegler
  @copyright:  None - Public domain

  @example:
    %mm_deleteGroup(TestGroup1);
    %mm_deleteGroup(TestGroup1,outputds=deletedGroup);

**/


/* deletes group */
%macro mm_deleteGroup(groupname,outputds=_null_);
    data &outputds.;
        delGroupFlag=metadata_delobj("omsobj:IdentityGroup?@Name='&groupname.'");
        if delGroupFlag=0 then put 'NOTE: Group ' "&groupname." ' successfully deleted.';
        else if delGroupFlag=-3 then put 'WARNING: Group ' "&groupname." ' not found.';
        else put 'ERROR: Group ' "&groupname." ' not deleted due to errors.';
    run;
%mend;
