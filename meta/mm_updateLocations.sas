/**
  @file: mm_updateLocations.sas
  @brief: updates information of locations (PASCODES) in metadata
  @details: given a dataset of valid pascodes, updates location
            objects in metadata 

  @param inputds: name of input dataset containing valid pascodes
    @required columns: pascode
  @param outputds=: name of output dataset containing flags
  @param pascode=: name of column containing pascode

  @returns outputds: dataset containing flags for update of users

  @version: SAS 9.4
  @author: Caleb Ziegler
  @copyright: None - Public domain

  @example:
    %mm_updateLocations(pascodes);

**/

%macro mm_updateLocations(inputds,outputds=work.updated_Locations,pascode=pascode);

    data &outputds.;
        length locationuri $256;
        length _location _locationNew _locArea $8;
        length _locType _locUsage $20;
        set &inputds.;
        /* pascode must be 8 alphanumeric only */
        if not prxmatch('/^\w{8}$/',strip(&pascode.)) then do;
            * invalid email;
            put 'ERROR: PASCODE: ' &pascode. ' is invalid. Not adding or updating this PASCODE.';
            delete;                
        end;
        /* associate pascode to person (create new pascode if no pascode in system) */
        locationuri="omsobj:Location?@Name='"||strip(&pascode.)||"'";
        locGetFlag=metadata_getattr(locationuri,"Name",_location);
        if locGetFlag < 0 then do;
            *we have to create a new location;
            locSetFlag=metadata_newobj("Location",locationuri,strip(&pascode.));
            locTypeSetFlag=metadata_setattr(locationuri,"LocationType","PASCODE");
            locUsageFlag=metadata_setattr(locationuri,"UsageVersion","1000000.0");
            locAreaFlag=metadata_setattr(locationuri,"Area",strip(&pascode.));
        end;
        else if (locGetFlag = 0 and _location=strip(&pascode.));
            *location already exists, update location information;
            locSetFlag=locGetFlag;
            locTypeSetFlag=metadata_getattr(locationuri,"LocationType",_locType);
            locUsageFlag=metadata_getattr(locationuri,"UsageVersion",_locUsage);
            locAreaFlag=metadata_getattr(locationuri,"Area",_locArea);
            if strip(_locType) ne "PASCODE" then do;
                locTypeSetFlag=metadata_setattr(locationuri,"LocationType","PASCODE");
            end;
            if strip(_locUsage) ne "1000000.0" then do;
                locUsageFlag=metadata_setattr(locationuri,"UsageVersion","1000000.0");
            end;
            if strip(_locArea) ne strip(&pascode.) then do;
                locAreaFlag=metadata_setattr(locationuri,"Area",strip(&pascode.));
            end;
        end;
         *log status of update;
        if sum(locSetFlag,locTypeSetFlag,locUsageFlag,locAreaFlag) = 0 then
            put 'NOTE: PASCODE: ' &pascode. ' updated successfully.';
        else put 'ERROR: Errors when updating PASCODE: ' &pascode.; 
    run;

%mend;
