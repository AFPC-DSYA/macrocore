/**
  @file: mm_removeLocations.sas
  @brief: removes old locations
  @details: given a dataset of valid locations containing pascode, 
            removes location objects in metadata that do not match
            a valid pascode

  @param inputds: name of input dataset containing valid pascodes
    @required columns: pascode
  @param outputds=: name of output dataset containing flags
  @param pascode=: name of column containing pascode

  @returns outputds: dataset containing flags for removal of locations

  @version: SAS 9.4
  @author: Caleb Ziegler
  @copyright: None - Public domain

  @example:
    %mm_removeLocations(validPascodes);

**/

%macro mm_removeLocations(inputds,outputds=work.removed_Locations,pascode=pascode);

    /* clean pascode on inputds*/
    data &inputds._clean;
        set &inputds.;
        /* pascode must be 8 alphanumeric only */
        if not prxmatch('/^\w{8}$/',strip(&pascode.)) then do;
            * invalid pascode;
            put 'ERROR: PASCODE: ' &pascode. ' is invalid. This PASCODE will be deleted.';
            delete;                
        end;
    run;
    /* get dataset of all pascodes in metadata */
    data work.metaPascodes;
        length locuri $256;
        length _pascode $8;
        call missing(locuri,_pascode);
        /* nobj tells number of objects, n is counter */
        nobj = 0;
        n=1;
        /* read off all location objects in metadata */
        do while(nobj >= 0);
            nobj=metadata_getnobj("omsobj:Location?@Id contains '.'",n,locuri);
            if nobj < 0 then continue;
            else do;
                /* get pascode for current location object */
                locGetFlag = metadata_getattr(locuri,"Name",_pascode);
                if locGetFlag = 0 then output;
                else continue;
            end;
            n=n+1;
        end;
        drop n locGetFlag;
    run;

    /* create dataset of pascodes to remove */
    PROC SQL;
        CREATE TABLE work.del_metaPascodes AS
        SELECT *
        FROM work.metaPascodes
        where _pascode not in (select &pascode. from &inputds._clean)
        ;
    QUIT;

    /* remove location objects with pascodes to remove */
    data &outputds.;
        length personuri $256;
        call missing(personuri);
        set work.del_metaPascodes;
       /* remove person associations without deleting people objects 
            note: locuri is for pascode to remove, personuri gets populated
                  for person object associated with location */
        k = 1;
        do while (metadata_getnasn(locuri,"Persons",k,personuri) > 0);
            personRemoveFlag=metadata_setassn(locuri,"Persons","Remove",personuri);
            k+1;
        end;
        /* delete location object */
        locDelFlag = metadata_delobj(locuri);
        if locDelFlag = 0 then put 'NOTE: location: ' _pascode ' successfully deleted.';
        else if locDelFlag = -2 then put 'ERROR: location : ' _pascode ' could not be deleted.';
        else if locDelFlag = -3 then put 'WARNING: location ' _pascode ' not found.';
        else put 'ERROR: Unable to connect to metadata server.'; 

        drop personuri;
    run;

%mend;

