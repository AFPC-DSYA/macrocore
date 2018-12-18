/**
  @file: mm_createUsers.sas
  @brief: creates Users in metadata 
  @details: given a dataset of people with firstname, lastname, 
            job title, pascode, email, and dodid, creates user accounts
            for each person

  @param inputds: name of input dataset containing people to create 
                  user accounts for 
    @required columns: firstname, lastname, job/duty title, pascode,
                       email, dodId/edipi (10 digit + 1 letter)
  @param groupname: string for name of group in metadata
  @param outputds=: name of output dataset containing flags
  @param firstname=: name of column containing first name
  @param lastname=: name of column containing last name
  @param title=: name of column containing job/duty title
  @param pascode=: name of column containing pascode
  @param email=: name of column containing email
  @param dodid=: name of column containing dodId/edipi (10 digit + 1 letter)

  @returns outputds: dataset containing flags for creation of users

  @version: SAS 9.4
  @author: Caleb Ziegler
  @copyright: None - Public domain

  @example:
    %mm_createUsers(profiles_full,TestGroup1);

**/

%macro mm_createUsers(inputds,groupname,outputds=work.created_Users,firstname=firstname,
                        lastname=lastname,title=title,pascode=pascode,email=email,dodid=gigid);
    data &outputds.;
        length personuri dodIduri locationuri emailuri loginuri login2uri defaultAuthUri webAuthUri $256;
        length _location emailtype $8;
        length name_space _personName _email $60;
        length _userId $11;
        /* set missing values to prevent unnecessary log statements */
        call missing(personuri,dodIduri,locationuri,emailuri,loginuri,login2uri,defaultAuthUri,webAuthUri,
                     _location,_personName,_email,_userId);
        set &inputds.;
        name_space = strip(strip(&lastname.)||" "||strip(&firstname.));
        if prxmatch('/us\.af\.mil/i',&email.) then emailtype='LIFE';
        else if prxmatch('/mail\.mil/i',&email.) then emailtype='PENTAGON';
        else emailtype='WORK';
        /* validate inputs with regular expressions */
        /* dodId must be 10 digits followed by 1 letter only */
        if not prxmatch('/^\d{10}\w{1}$/',strip(&dodid.)) then do;
            * invalid dodID;
            put 'ERROR: User: ' &dodid. ' with Name: ' name_space ' has invalid dodID. Not creating user.';
            delete;            
        end;
        /* name cannot be blank */
        else if strip(name_space) = "" then do;
            * invalid name;
            put 'ERROR: User: ' &dodid. ' with Name: ' name_space ' has invalid name. Not creating user.';
            delete; 
        end;
        /* email must be alphanumeric and period separated by @ */
        else if not prxmatch('/[\w\.]+@[\w\.]+/',&email.) then do;
            * invalid email;
            put 'ERROR: User: ' &dodid. ' with Name: ' name_space ' has invalid email. Not creating user.';
            delete;                
        end;
        /* pascode must be 8 alphanumeric only */
        else if not prxmatch('/^\w{8}$/',strip(&pascode.)) then do;
            * invalid email;
            put 'ERROR: User: ' &dodid. ' with Name: ' name_space ' has invalid PASCODE. Not creating user.';
            delete;                
        end;
        /* find if user already in STARS 
            (first check if name conflicts then check if dodid conflicts)*/
        personuri = "omsobj:Person?@Name='"||strip(&dodid.)||"'";
        personGetFlag=metadata_getattr(personuri,"Name",_personName);
        dodIduri = "omsobj:Login?@UserID='"||strip(&dodid.)||"'";
        userIdGetFlag=metadata_getattr(dodIduri,"UserID",_userId);
        if personGetFlag = 0 or userIdGetFlag = 0 then do;
            * person already created, move to next record;
            put 'WARNING: User: ' &dodid. ' with Name: ' name_space ' already exists in STARS. Not creating user.';
            delete;
        end;
        else do;
            * person not in STARS and has correct dodid/name, create new user;
            personFlag=metadata_newobj("Person",personuri,strip(&dodid.));
            usageFlag=metadata_setattr(personuri,"UsageVersion","1000000.0");
            publicFlag=metadata_setattr(personuri,"PublicType","User");
            displayFlag=metadata_setattr(personuri,"DisplayName",name_space);
            titleFlag=metadata_setattr(personuri,"Title",strip(&title.));
            /* associate pascode to person */
            locationuri="omsobj:Location?@Name='"||strip(&pascode.)||"'";
            locGetFlag=metadata_getattr(locationuri,"Name",_location);
            if locGetFlag < 0 then do;
                *location does not exist ;
                put 'WARNING: : ' &pascode. ' does not exist in STARS. Not assigning location to User: ' &dodid. ' with Name: ' name_space ;
            end;
            else do;
                *location already created, just set association for person;
                locSetFlag=metadata_setassn(personuri,"Locations","Append",locationuri);
            end;
            /* add new email (create new email if not in system) */
            emailuri="omsobj:Email?@Address='"||strip(&email.)||"'";
            emailGetFlag=metadata_getattr(emailuri,"Address",_email);
            if emailGetFlag < 0 then do;
                *we have to create an email;
                emailFlag=metadata_newobj("Email",emailuri,strip(emailtype),"Foundation",personuri,"EmailAddresses");
                eAddressFlag=metadata_setattr(emailuri,"Address",strip(&email.));
                eTypeFlag=metadata_setattr(emailuri,"EmailType",strip(emailtype));
                eUsageFlag=metadata_setattr(emailuri,"UsageVersion","0.0");
            end;
            else do;
                *email already created, just associate for person;
                emailFlag=metadata_setassn(personuri,"EmailAddresses","Append",emailuri);
            end;
            /* add login  */
            defaultAuthUri="omsobj:AuthenticationDomain?@Name='DefaultAuth'";
            webAuthUri="omsobj:AuthenticationDomain?@Name='Web'";
            loginFlag=metadata_newobj("Login",loginuri,strip(&dodid.),"Foundation",personuri,"Logins");
            login2Flag=metadata_newobj("Login",login2uri,"AREA52\"||strip(&dodid.),"Foundation",personuri,"Logins");
            domainFlag=metadata_setassn(loginuri,"Domain","Append",webAuthUri);
            domain2Flag=metadata_setassn(login2uri,"Domain","Append",defaultAuthUri);
            userIdFlag=metadata_setattr(loginuri,"UserID",strip(&dodid.));
            userId2Flag=metadata_setattr(login2uri,"UserID","AREA52\"||strip(&dodid.));
            lPublicFlag=metadata_setattr(loginuri,"PublicType","Login");
            lPublic2Flag=metadata_setattr(login2uri,"PublicType","Login");
            changeFlag=metadata_setattr(loginuri,"ChangeState",strip(&dodid.));
            change2Flag=metadata_setattr(login2uri,"ChangeState","AREA52\"||strip(&dodid.));
            
            /* log overall result*/
            if sum(personFlag,usageFlag,displayFlag,titleFlag,locSetFlag,emailFlag,eAddressFlag,
                    eTypeFlag,eUsageFlag,eAssnFlag,loginFlag,domainFlag,userIdFlag,lPublicFlag,changeFlag,
                    login2Flag,domain2Flag,userId2Flag,lPublic2Flag,change2Flag) = 0 then
                put 'NOTE: User: ' &dodid. ' with Name: ' name_space ' created successfully';
            else if locGetFlag < 0 then put 'WARNING: User: ' &dodid. ' created but cannot assign PASCODE for user.';
            else put 'ERROR: User: ' &dodid. ' with Name: ' name_space ' has errors. Check dataset "&outputds." for more information.';
        end;

        drop personuri locationuri emailuri loginuri login2uri defaultAuthUri webAuthUri;
    run;

    %if not(%nrbquote(&groupname.)=) %then %mm_addUsersToGroup(&groupname.,&inputds.,dodId=&dodId.);
%mend;
