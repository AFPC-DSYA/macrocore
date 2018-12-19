/**
  @file
  @brief Creates dataset with all members of a metadata group
  @details

  @param group metadata group for which to bring back members
  @param outds= the dataset to create that contains the list of members
  @param id= set to yes if passing an ID rather than a group name

  @returns outds  dataset containing all members of the metadata group

  @version 9.2
  @author Allan Bowe
  @copyright GNU GENERAL PUBLIC LICENSE v3

**/

%macro mm_getgroupmembers(
    group /* metadata group for which to bring back members */
    ,outds=work.mm_getgroupmembers /* output dataset to contain the results */
    ,id=NO /* set to yes if passing an ID rather than group name */
    ,contains=NO /* set to yes if name contains rather than equals */
)/*/STORE SOURCE*/;
  %local attr condition;
  %if &id=NO %then %do;
    %let attr = Name;
    %if &contains=YES %then %do;
      %let condition = contains;
    %end;
    %else %do;
      %let condition = eq;
    %end;
  %end;
  %else %do;
    %let attr = Id;
    %let condition = eq;
  %end;

  data &outds ;
    attrib uriGrp uriMem uriLogin GroupId GroupName Group_or_Role MemberName MemberType MemberId
                          length=$64
      GroupDesc           length=$256
      rcGrp rcMem rc i j  length=3;
    call missing (of _all_);
    drop uriGrp uriMem uriLogin rcGrp rcMem rc i j k;

    i=1;
    * Grab the URI for the first Group ;
    * If Group found, enter do loop ;
    do while (metadata_getnobj("omsobj:IdentityGroup?@&attr &condition '&group'",i,uriGrp) > 0);
      call missing (rcMem,uriMem,uriLogin,GroupId,GroupName,Group_or_Role
        ,MemberName,MemberId,MemberType);
      * get group info ;
      rc = metadata_getattr(uriGrp,"Id",GroupId);
      rc = metadata_getattr(uriGrp,"Name",GroupName);
      rc = metadata_getattr(uriGrp,"PublicType",Group_or_Role);
      rc = metadata_getattr(uriGrp,"Desc",GroupDesc);
      j=1;
      do while (metadata_getnasn(uriGrp,"MemberIdentities",j,uriMem) > 0);
        call missing (MemberName,MemberType,MemberId,uriLogin);
        rc = metadata_getattr(uriMem,"Name",MemberName);
        rc = metadata_getattr(uriMem,"PublicType",MemberType);
        if strip(MemberType) = "User" then do;
          k=1;
          do while (metadata_getnasn(uriMem,"Logins",k,uriLogin) > 0);
            k+1;
            if prxmatch('/^\d{10}[A-Z]{1}$/',strip(MemberId)) then do;
              continue;
            end;
            else do;
              rc = metadata_getattr(uriLogin,"UserID",MemberId);
            end;
          end;
        end;
        output;
        j+1;
      end;
      i+1;
    end;

  run;

%mend;
