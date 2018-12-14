/**
  @file: mm_updateRemoveLocations.sas
  @brief: updates information of locations (PASCODES) in metadata and
            removes old locations
  @details: given a dataset of valid locations containing pascode, 
            updates location objects in metadata and removes location 
            objects in metadata that do not match a valid pascode

  @param inputds: name of input dataset containing valid pascodes
    @required columns: pascode
  @param outputds=: name of output dataset containing flags
  @param pascode=: name of column containing pascode

  @returns outputds: dataset containing flags for update and removal of locations

  @dependencies: mm_updateLocations.sas; mm_removeLocations.sas

  @version: SAS 9.4
  @author: Caleb Ziegler
  @copyright: None - Public domain

  @example:
    %mm_updateRemoveLocations(validPascodes);

**/

%macro mm_updateRemoveLocations(inputds,outputds=work.changed_Locations,pascode=pascode);
    %mm_updateLocations(&inputds.,outputds=work.updated_Locations,pascode=&pascode.);
    %mm_removeLocations(&inputds.,outputds=work.removed_Locations,pascode=&pascode.);
    data &outputds.;
        set work.updated_Locations
            work.removed_Locations
        ;
    run;
%mend;
