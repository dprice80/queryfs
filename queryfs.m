function [Q] = queryfs(Q)
%%% queryfs checks through all specified directories and returns
%%% a structure containing data about the files found.
%%%
%%% Inputs:
%%% queryfs takes a structure with at least one field
%%% (searchpaths) (see below for example)
%%%
%%% Working Example (using included example_filesystem): 
%%% Simple (one ID no wildcards):
%%%     Q = []; % Always ensure Q is cleared
%%%     Q.rootdir 
%%%     Q.infocsv = '/example_filesystem/id_info.csv'; % Path to subject info
%%%     Q.searchpaths = {
%%%       'MEG' '/imaging/pathtodata/<ID>/rest/autobad_sss_skip20_fl_rest.fif'
%%%       }; % Defines the file paths to search (may use wildcards)
%%%     Q = query_files(Q)
%%%
%%% id_info.csv is a comma separated csv file containing all user IDs.
%%% Column headers define the ID tag used in the search query (i.e. <ID> in above example)
%%%
%%% Optional Inputs
%%%             rootdir: Optional Input: Default = ''     Prefix for all search paths e.g. '/imaging/projname/mri/'
%%%           listfound: Optional Input: Default = false  Lists all files found durng search
%%%     returnfirstfile: Optional Input: Default = false  When multiple files are found set true to retrieve
%%%                                                        the first in list otherwise show warning and return nothing
%%%
%%% Searches are constructed by placing tags into a search query
%%% as follows
%%%     /path/to/data/<ID>/filename_session1.fif
%%%
%%% In this example <ID> replaces the ID of the participant.
%%%
%%% If there is any inconsistency in the filename or filepath, replace with
%%% a wildcard * as in linux ls commands.
%%%
%%% For example if the above had 2 possible sessions, to find 'either' session1 or session2
%%% replace the part of the filename that varies with a wildcard.
%%%
%%%     /imaging/pathtodata/<ID>/filename_session*.fif
%%%
%%% Output
%%%     Q: A structure containing below field:
%%%         .searchpaths: {'SessionLabel'  'filepath/...'}     % The original query
%%%        .fileindexmat: [708x1 logical]                      % Logical index indicating the existence of files matching the search query for each subject
%%%             .rootdir: ''                                   % Optional Input: Prefix for all search paths.
%%%           .listfound: 0                                    % Optional Input: Lists all files found durng search
%%%     .returnfirstfile: 0                                    % Optional Input: when multiple files are found set true to retrieve the first in list
%%%            .idsfound: [1x1 struct]                         % Correct IDs per result. Each query is contained in a separate field
%%%           .filenames: [1x1 struct]                         % Full file names without wildcards for each subject and each query
%%%           .fileindex: [1x1 struct]                         % Same as fileindexmat, but each query is contained in a separate field
%%%            .fileinfo: [1x1 struct]                         % Contains date created (as given by OS) for each file found
%%%            .allexist: [1xN double]                         % Numeric index for subjects that match all queries [same as find(all(Q.fileindexmat,2)) ]
%%%
%%%
%%% 
%%%
%%% Example: Complex: (2 ID types, and wildcard)
%%%
%%% Start with the path /imaging/pathtodata/CBU130802/RestingState/sswarfMR13010_CC220974-0002.nii
%%%
%%% Confirm it exists for at least 1 subject
%%%
%%%     >> ls /imaging/pathtodata/CBU130802/RestingState/sswarfMR13010_CC220974-0002.nii
%%%
%%% If it didn't exist you would see an error here
%%%
%%% Replace the parts that might vary with a wildcard (usually numbers / timestamps generated by scanners etc)
%%%     /imaging/pathtodata/CBU130802/RestingState/sswarfMR*_CC220974-*.nii
%%%
%%% Replace the two IDs with tags (it is necessary to use 280 tags here)
%%%     /imaging/pathtodata/<MRIID>/RestingState/sswarfMR*_<ID1>-*.nii
%%%
%%% Where ID1 and MRIID are user-defined as headers in userqueries.csv
%%%
%%% Next, construct a query called "smooth" using the above search path.
%%%
%%%     Q.searchpaths = {
%%%         'smooth' '/imaging/pathtodata/<MRIID>/RestingState/sswarfMR*_<ID1>-0002.nii'
%%%         };
%%%     Q = queryfs(Q);
%%%
%%% View / get all filenames by typing
%%% filenames = Q.filenames.smooth
%%%
%%% Get only those files that exist
%%% filenames = Q.filenames.smooth(Q.fileindex.smooth)
%%%
%%% Darren Price. Last Updated (02/09/2017)

fsinfo = csvimport(Q.infocsv,'outputAsChar',true);
idhead = fsinfo(1,:);
fsinfo = fsinfo(2:end, :);

Nsubs = size(fsinfo,1);%#ok<*USENS>

if ~isfield(Q,'sublist')
    Q.sublist = 1:Nsubs;
end

% Load dataflags
% C = csvimport('dataflags.csv','delimiter','\t');

% Check Files Exist.
Q.fileindexmat = false(Nsubs,size(Q.searchpaths,1));

if ~isfield(Q,'rootdir')
    Q.rootdir = '';
end

if ~isfield(Q,'debug')
    Q.debug = false;
end

if ~isfield(Q,'returnfirstfile')
    Q.returnfirstfile = 0;
end


if ~isfield(Q,'verbose')
    Q.verbose = false;
    printprogCR = false;
elseif Q.verbose == true
    printprogCR = true;
    Q.listfound = true;
else
    printprogCR = false;
end


if ~isfield(Q,'listfound')
    Q.listfound = false;
end


% Validate search paths
for sesi = 1:size(Q.searchpaths,1)
    sp = Q.searchpaths{sesi,2};
    if Q.debug == false
        if isempty(regexp(sp, '<*>','ONCE'))
            disp(['ERROR in: ' Q.searchpaths{sesi,1}])
            error('No tag (i.e. <ID>) found in search string')
        end
    end
end

for hi = 1:length(idhead)
    Q.ID.(idhead{hi}) = fsinfo(:,hi);
end

for sesi = 1:size(Q.searchpaths,1)
%     Q.idsfound.(Q.searchpaths{sesi,1}) = cell(Nsubs,1); % will write right in to Q so set up cells. Also ensures output is always required size
    Q.filenames.(Q.searchpaths{sesi,1}) = cell(1,Nsubs);
    Q.fileindex.(Q.searchpaths{sesi,1}) = false(Nsubs,1);
    Q.dataflags.(Q.searchpaths{sesi,1}).Message = '';
    Q.dataflags.(Q.searchpaths{sesi,1}).Index = false(Nsubs,1);

    fprintf('\n\nChecking: %s', Q.searchpaths{sesi,1})
    
    if size(Q.searchpaths, 2) == 3
        sesuse = Q.searchpaths{sesi,3}; % assign the session search list
    else
        sesuse = 1:4;
    end
    
    for ii = Q.sublist
        printProgress(ii, Nsubs, printprogCR)
        
        Format = fullfile(Q.rootdir,Q.searchpaths{sesi,2});
        [st, en] = regexpi(Format, '<([><A-Z|0-9]){1,}>');
        
        % Check which tags are in Format
        tags = {};
        tagsref = {};
        tagsfmt = {};
        for ti = 1:length(st)
            tagstr = splitstring(Format(st(ti)+1:en(ti)-1),'|');
            for tsi = 1:length(tagstr)
                tags{end+1} = tagstr{tsi}; %#ok<AGROW>
                tagsref{end+1} = Q.searchpaths{sesi,1}; %#ok<AGROW>
                tagsfmt{end+1} = Format(st(ti)+1:en(ti)-1);  %#ok<AGROW> Associate this tag with the tag set
            end
        end

        tagmem = ismember(tags, idhead);
        if any(ismember(tags, idhead) == 0)
            error([
                sprintf('The following tags were not found in ID list (%s) for session %s: ', Q.infocsv, Q.searchpaths{sesi,1}),...
                sprintf('<%s> ', tags{tagmem == 0})
                ]);
        end
        
        % Replace non OR tags (tags have been verified here)
        for ti = 1:length(tags)
            if isempty(strfind(tagsfmt{ti},'|')) % exclude OR operators for now
                ci = strcmp(idhead, tags{ti}); % find col index of tag
                if ~isempty(fsinfo{ii,ci}) % only replace column if ID is not emtpy.
                    Format = strrep(Format, sprintf('<%s>',tagsfmt{ti}), fsinfo{ii,ci});
                end
            end
        end
        
        FormatLogical = {};
        DLogical = {};
        D = [];
        % Now loop through logical tags
        if ~isempty(strfind(Format,'|')) % if any tags contain OR operators loop through them, otherwise go straight to search
            dfound = false; % Loop will skip once first file is found
            for ti = 1:length(tags)
                if ~isempty(strfind(tagsfmt{ti},'|')) && dfound == false
                    ci = strcmp(idhead, tags{ti}); % find col index of tag
                    if ~isempty(fsinfo{ii,ci}) % only replace column if ID is not emtpy.
                        FormatLogical = strrep(Format, sprintf('<%s>',tagsfmt{ti}), fsinfo{ii,ci});
                        [D, FormatLogical] = findfile(FormatLogical, Q.returnfirstfile);
                        if ~isempty(D)
                            dfound = true;
                        end
                    end
                end
            end
            Format = FormatLogical;
        else
            [D, Format] = findfile(Format, Q.returnfirstfile);
        end
        
        % Add Date Info
        if ~isempty(D)
            if ~isempty(D(1).datenum)
                Q.fileinfo.(Q.searchpaths{sesi,1}).datestr{ii} = D.date;
                Q.fileinfo.(Q.searchpaths{sesi,1}).datenum(ii) = D.datenum;
            else
                Q.fileinfo.(Q.searchpaths{sesi,1}).datestr{ii} = 0;
                Q.fileinfo.(Q.searchpaths{sesi,1}).datenum(ii) = 0;
            end
            % Add correct IDs (probably not necessary unless >1 ID possible for each ID type
%             for tag = tags
%                 Q.CorrectID.(Q.searchpaths{sesi,1}).(tag{1})(ii) = Q.ID.(tag{1})(ii);
%             end
        end
        
        % Figure out action to take
        action = 0;
        if size(D,1) == 1
            action = 2; % only 1 result so return filepath
        elseif size(D,1) == 0
            action = 3; % no result, do nothing
        elseif size(D,1) > 1
            if ~isfield(Q,'returnfirstfile')
                action = 1; % warn that multiple files exist
            elseif Q.returnfirstfile == 0
                action = 1; % warn that multiple files exist
            elseif Q.returnfirstfile == 1
                action = 4; % return the first file in list
            end
        end
        
        % Perform action
        switch action
            case 1 % multiple files
                if Q.returnfirstfile == 1
                    lsOut = [fileparts(Format) D(ii).name];
                    Q.fileindexmat(ii,sesi) = true;
                    Q.filenames.(Q.searchpaths{sesi,1}){ii}; %#ok<VUNUS>
                    Q.fileindex.(Q.searchpaths{sesi,1})(ii,1) = 1;
                    if Q.listfound; fprintf('%s         \n', lsOut); end
                else
                    warning(['The following files were found for your query: ' Format])
                    warning('Set Q.returnfirstfile = 1 if you want to use the first file');
                    dir(Format)
                    fprintf(1,'\n\n     ');
                end
                
            case 2 % One file found
                [folder, NULL, NULL] = fileparts(Format); %#ok<*NASGU>
                lsOut = fullfile(folder,D.name);
                Q.fileindexmat(ii,sesi) = true;
                Q.filenames.(Q.searchpaths{sesi,1}){ii} = lsOut;
                Q.fileindex.(Q.searchpaths{sesi,1})(ii,1) = 1;

            case 3
                % Do nothing
                
            case 4 % Select first file from multiple files found
                D = D(1);
                [folder, NULL, NULL] = fileparts(Format);
                lsOut = fullfile(folder,D.name);
                Q.fileindexmat(ii,sesi) = true;
                Q.filenames.(Q.searchpaths{sesi,1}){ii} = lsOut;
                Q.fileindex.(Q.searchpaths{sesi,1})(ii,1) = 1;
        end
        
        if Q.listfound && (action == 2 || action == 4)
            disp('      ');
            disp(lsOut);
        end
        
        % Check whether the file being searched for contains dicom header
        % info. If so, and the CCID is being used as a search crieria
        % within that file name, then remove and warn user.
        if ~isempty(Q.filenames.(Q.searchpaths{sesi,1}){ii})
            CheckFilenameForCCID(Q, sesi, Q.filenames.(Q.searchpaths{sesi,1}){ii}); % will throw error if fails test
        end
        

%         % Check for data flags and report
%         FormattedPath = Q.filenames.(Q.searchpaths{sesi,1}){ii};
%         if ~isempty(FormattedPath)
%             for ci = 2:size(C,2)
%                 if ~isempty(regexp(FormattedPath, C{1, ci},'ONCE')) && Q.fileindexmat(ii,sesi) == true && int8(str2double(C{ii+3, ci})) == 1
%                     Q.dataflags.(Q.searchpaths{sesi,1}).(C{2, ci}).message = C{3, ci};
%                     Q.dataflags.(Q.searchpaths{sesi,1}).(C{2, ci}).flag(ii,1) = true;
%                     flagfound = true;
%                     fprintf('\n')
%                     fprintf('Data Flag: %s:  %s', SubCCIDc{ii}, C{3, ci})
%                     fprintf('          ')
%                 end
%             end
%         end
        % end flag checks.
    end
    
    fprintf(1,['\nTotal files found: ' num2str(sum(Q.fileindexmat(:,sesi))) '\n\n--------------------------\n\n']);
    if sum(Q.fileindexmat(:,sesi)) == 0
        warning('Check your file paths and that you have used the correct ID type')
        disp(['The last path searched for was ' Format])
        disp('NOTE: In order to select only the first file from a list (such as a list of dicoms), set Q.returnfirstfile = 1')
    end
    if isfield(Q, 'extractfun') && isa(Q.extractfun, 'function_handle')
        Q.extracted.(Q.searchpaths{sesi,1}) = Q.extractfun(Q.filenames.(Q.searchpaths{sesi,1}));
    end
end

Q.allexist = find(all(Q.fileindexmat,2))';

% Remove bad subjects
if isfield(Q,'ExcludeSubjects')
    Q = CCQuery_ExcludeSubjects(Q);
end

%     function [Q, D, Format] = findfile(Format, Sub280MRIIDc, Q)
%         if ~isempty(strfind(Format,'<MRI280ID>'))   % use 280 list
%             D = [];
%             found = 0;
%             for sfi = sesuse
%                 if ~strcmp(Sub280MRIIDc{ii,sfi},'') && found == 0
%                     [D2, Format2] = FindFiles(strrep(Format,'<MRI280ID>',Sub280MRIIDc{ii,sfi}),Q.returnfirstfile);
%                     if ~isempty(D2)
%                         Q.idsfound.(Q.searchpaths{sesi,1}){ii,1} = Sub280MRIIDc{ii,sfi}; % record correct subject ID
%                         Q.SessNumFound.(Q.searchpaths{sesi,1})(ii) = sfi;
%                         Format = Format2; % change Format to correct file location
%                         D = D2;
%                         found = 1;
%                     end
%                 end
%             end
%         else
%             [D, Format] = FindFiles(Format,Q.returnfirstfile); % use 700
%             Q.idsfound.(Q.searchpaths{sesi,1}){ii} = SubCBUIDc{ii};
%         end
%     end

    function [D, Format] = findfile(Format, FirstFile)
        [fol, NULL, NULL] = fileparts(Format);
        if Q.debug == true;
            fprintf('Search string %s \n\n              ',Format)
        end
        if ~isempty(strfind(fol,'*')) % use ls to get an exact folder path if folder contains * (slows the script down)
            try
                L = ls(Format); % use ls to get file list using * (because it doesn't work with dir if * is in path folder names)
                L = textscan(L,'%s');
                L = L{1};
                
                if length(L) > 1 % there will only be a > 1 line feed if multiple items found.
                    % if more than one line then either warn user or just pick first file based on value in Q.returnfirstfile
                    if FirstFile == 1
                        L = L(1);
                    else
                        warning('More than one file found. Set Q.returnfirstfile = 1 if you want to use the first file');
                    end
                end
                D = dir(L{1}); % Once the path has been worked out, then use dir, which gives the proper D structure.
                Format = L{1};
            catch %#ok<*CTCH>
                D = []; % no file found (ls annoyingly causes an error if no file was found).
            end
        else
            % no need for ls (faster)
            D = dir(Format);
        end
    end

    function [] = CheckFilenameForCCID(Q,sesi,Format)
        [NULL, ffile, NULL] = fileparts(Format); %#ok<SETNU>
        [NULL, dfile, NULL] = fileparts(Q.searchpaths{sesi,2});
        
        if ~isempty(strfind(ffile, 'MR1')) && (~isempty(strfind(dfile, 'CC')) || ~isempty(strfind(dfile, 'cc')))
            fprintf('\n\n\n')
            disp('################################################################')
            disp('####################   ERROR MESSAGE   #########################')
            disp('Please use the folder name to identify data rather than filename.')
            disp('Unfortunately, filename IDs may contain typographic errors that could')
            disp('result in data being missed. Folder names have been carefully verified')
            disp('and should not contain any errors.')
            disp('For example you searched for: ')
            disp(['    ', Q.searchpaths{sesi,2}])
            disp('you should instead search for (using a wildcard in place of the filename ID): ')
            checkstrings = {'<CCID>', '<CC280ID>', '<ccID>', '<cc280ID>'};
            fi = cellfun(@(t) ~isempty(strfind(Q.searchpaths{sesi,2}, t)), checkstrings, 'UniformOutput',true);
            disp(['    ', strrep(Q.searchpaths{sesi,2}, checkstrings{fi},'*')])
            disp('while including an ID tag in the folder path.')
            disp('################################################################')
            disp('################################################################')
            fprintf('\n')
            error(sprintf('The CCID tag found in the filename may conflict with a possible\n typo in the filename. See above message for more information.')) %#ok<SPERR>
        end
    end

end
