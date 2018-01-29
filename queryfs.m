classdef queryfs < handle
%     queryfs checks through all specified directories and returns
%     a structure containing data about the files found.
%     Working Example (using the provided example filesystem): 
%     
%        clear q
%        q = queryfs('example_filesystem/id_info.csv');
%        q.addsearchpath('example1','example_filesystem/<STUDYID>/file_<ID1>_*.mat');
%        q.checkfiles
% 
%     To check either ID1 or ID2 use logical syntax <ID1|ID2|ID..>. For example
%     q.addsearchpath('example1','example_filesystem/<STUDYID>/file_<ID1|ID2>_*.mat');
% 
%     Options may be set using the dot notation. e.g. q.verbose = true;
%
%     Properties:
%       Required:
%         idlist:       Set as the first argument of queryfs (see
%                       example above).
%       Optional (set as object properties, e.g. q.verbose = true;):
%         rootdir:      default = ''. Root path to be appended to all
%                       searchpaths
%         verbose:      display search details. default = false
%         selectfirstfile: When multiple files are found, select only the
%                       first file alphabetically (default = false)
%         extractfun:   Function handle linking to the function to run on each set of filepaths found.
%                       This function should take a cell array of filepaths as input,
%                       ignoring empty cells. The output can be any single matlab
%                       variable (struct, array, cell array etc).
%         sublist:      defined by queryfs, but user may overwrite.
%                       Specify rows of idlist to be searched
% 
%     Output (read only attributes of q)
%         fileindexmat:     Matrix containing a logical file index matrix,
%                           1 col per search path
%         ID:               struct - IDs imported from idlist
%         filenames:        struct - filnames found for each named searchpath. Empty
%                           cells where files were not found
%         fileindex:        struct - 1xN logical array for each searchpath
%         extracted:        struct - Data extracted using extractfun
%         fileinfo:         struct - date / time information for each file
%                           found
%         allexist:         linear index (e.g. [1 2 4 6 8]) for rows of
%                           idlist where all data was found

    properties
        idlist = ''
        rootdir = ''
        verbose = false
        selectfirstfile = false
        extractfun
        searchpaths
        sublist
    end
    
    properties (SetAccess = private)
        fileindexmat
        ID
        filenames
        fileindex
        extracted
        fileinfo
        seriesnumbers
        allexist
    end
    
    properties (Hidden)
        idhead
        iddata
    end
    
    %     methods (Hidden)
    %         function addlistener(obj, property, eventname, callback)
    %             addlistener@addlistener(obj, property, eventname, callback)
    %         end
    %     end
    
    methods
        function obj = queryfs(idlist, searchpaths)
            
            % Check paths
            if ~exist('splitstring','file')
                addpath([fileparts(mfilename('fullpath')) '/utils'])
            end
            
            
            
            
            if nargin == 0
                error('At least one argument is required, idlist and optional searchpaths. See <a href="matlab:edit query_files_obj_example.m">query_files_obj_example.m</a>')
            elseif nargin >= 1
                if exist(idlist,'file')
                    obj.idlist = idlist;
                else
                    error('queryfs:idlistnotfound', 'Could not find specified idlist %s', idlist)
                end
                obj.iddata = csvimport(obj.idlist,'outputAsChar',true);
                obj.idhead = obj.iddata(1,:);
                obj.iddata = obj.iddata(2:end, :);
                
                Nsubs = size(obj.iddata,1);%#ok<*USENS>
                
                if ~isempty(obj.idlist)
                    obj.sublist = 1:Nsubs;
                end
                
                for hi = 1:length(obj.idhead)
                    obj.ID.(obj.idhead{hi}) = obj.iddata(:,hi);
                end
            end
            
            if nargin == 2           
                obj.searchpaths = searchpaths;
                obj.idlist = idlist;
                obj.checkfiles();
            end
            
            % Load dataflags
            % C = csvimport('dataflags.csv','delimiter','\t');
            
            % Check Files Exist.
            obj.fileindexmat = false(Nsubs,size(obj.searchpaths,1));
            
        end
        
        function obj = addsearchpath(obj, name, path)
            if nargin == 2
                if iscell(name)
                    obj.searchpaths = name;
                else
                    error('When using only one input, argument 1 should be a cell array {''name'' ''searchpaths''}')
                end
                return
            end
            
            if isempty(obj.searchpaths)
                obj.searchpaths = {name path};
            else
                if ~strcmp(obj.searchpaths(:,1), name)
                    obj.searchpaths = [obj.searchpaths; {name path}];
                else
                    error('queryfs:nameexists','Name %s already exists in the searchpaths', name)
                end
            end
        end
        
        function checkfiles(obj)
            
            if ~obj.verbose
                printprogCR = false;
            else
                printprogCR = true;
            end
            
            Nsubs = size(obj.iddata,1);
            
            % Validate search paths
            for sesi = 1:size(obj.searchpaths,1)
                sp = obj.searchpaths{sesi,2};
                if obj.verbose == false
                    if isempty(regexp(sp, '<*>','ONCE'))
                        disp(['ERROR in: ' obj.searchpaths{sesi,1}])
                        error('No tag (i.e. <ID>) found in search string')
                    end
                end
            end
            
            for sesi = 1:size(obj.searchpaths,1)
                %     obj.CorrectSubIDc.(obj.searchpaths{sesi,1}) = cell(Nsubs,1); % will write right in to Q so set up cells. Also ensures output is always required size
                obj.filenames.(obj.searchpaths{sesi,1}) = cell(1,Nsubs);
                obj.fileindex.(obj.searchpaths{sesi,1}) = false(Nsubs,1);
%                 obj.dataflags.(obj.searchpaths{sesi,1}).Message = '';
%                 obj.dataflags.(obj.searchpaths{sesi,1}).Index = false(Nsubs,1);

                fprintf('\n\nChecking: %s', obj.searchpaths{sesi,1})
                
                if size(obj.searchpaths, 2) == 3
                    sesuse = obj.searchpaths{sesi,3}; % assign the session search list
                else
                    sesuse = 1:4;
                end
                
                for ii = shiftdim(obj.sublist)'
                    printProgress(ii, Nsubs, printprogCR)
                    
                    if obj.verbose == 1
                        fldn = fieldnames(obj.ID);
                        fprintf('\n--------------------------------------------------\n')
                        for fli = 1:length(fldn)
                            fprintf('%s: %s | ', fldn{fli}, obj.ID.(fldn{fli}){ii})
                        end
                        fprintf('\n')
                    end
                    
                    Format = fullfile(obj.rootdir,obj.searchpaths{sesi,2});
                    [st, en] = regexpi(Format, '<([><A-Z|0-9]){1,}>');
                                        
                    % Check which tags are in Format
                    tags = {};
                    tagsref = {};
                    tagsfmt = {};
                    for ti = 1:length(st)
                        tagstr = splitstring(Format(st(ti)+1:en(ti)-1),'|');
                        for tsi = 1:length(tagstr)
                            tags{end+1} = tagstr{tsi}; %#ok<AGROW>
                            tagsref{end+1} = obj.searchpaths{sesi,1}; %#ok<AGROW>
                            tagsfmt{end+1} = Format(st(ti)+1:en(ti)-1);  %#ok<AGROW> Associate this tag with the tag set
                        end
                    end
                    
                    tagmem = ismember(tags, obj.idhead);
                    if any(ismember(tags, obj.idhead) == 0)
                        error([
                            sprintf('The following tags were not found in ID list (%s) for session %s: ', obj.idlist, obj.searchpaths{sesi,1}),...
                            sprintf('<%s> ', tags{tagmem == 0})
                            ]);
                    end
                    
                    
                    %%%%%%%%%
                    % Replace non OR tags (tags have been verified here)
                    for ti = 1:length(tags)
                        if isempty(strfind(tagsfmt{ti},'|')) % exclude OR operators for now
                            ci = strcmp(obj.idhead, tags{ti}); % find col index of tag
                            if ~isempty(obj.iddata{ii,ci}) % only replace column if ID is not emtpy.
                                Format = strrep(Format, sprintf('<%s>',tagsfmt{ti}), obj.iddata{ii,ci});
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
                            if ~isempty(strfind(tagsfmt{ti},'|')) && dfound == false % skip if file found already
                                ci = strcmp(obj.idhead, tags{ti}); % find col index of tag
                                if ~isempty(obj.iddata{ii,ci}) % only replace column if ID is not emtpy.
                                    FormatLogical = strrep(Format, sprintf('<%s>',tagsfmt{ti}), obj.iddata{ii,ci});
                                    [D, FormatLogical] = findfile(FormatLogical, obj.selectfirstfile);
                                    if ~isempty(D)
                                        dfound = true;
                                    end
                                end
                            end
                        end
                        Format = FormatLogical;
                    else
                        [D, Format] = findfile(Format, obj.selectfirstfile);
                    end
                   
                    % Add Date Info
                    if ~isempty(D)
                        if ~isempty(D(1).datenum)
                            obj.fileinfo.(obj.searchpaths{sesi,1}).datestr{ii} = D.date;
                            obj.fileinfo.(obj.searchpaths{sesi,1}).datenum(ii) = D.datenum;
                        else
                            obj.fileinfo.(obj.searchpaths{sesi,1}).datestr{ii} = 0;
                            obj.fileinfo.(obj.searchpaths{sesi,1}).datenum(ii) = 0;
                        end
                        % Add correct IDs (probably not necessary unless >1 ID possible for each ID type
                        %             for tag = tags
                        %                 obj.CorrectID.(obj.searchpaths{sesi,1}).(tag{1})(ii) = obj.ID.(tag{1})(ii);
                        %             end
                    end
                    
                    % Figure out action to take
                    action = 0;
                    if size(D,1) == 1
                        action = 2; % only 1 result so return filepath
                    elseif size(D,1) == 0
                        action = 3; % no result, do nothing
                    elseif size(D,1) > 1
                        if ~obj.selectfirstfile
                            action = 1; % warn that multiple files exist
                        else
                            action = 4; % return the first file in list
                        end
                    end
                    
                    % Perform action
                    switch action
                        case 1 % multiple files
                            if obj.selectfirstfile == 1
                                lsOut = [fileparts(Format) D(ii).name];
                                obj.fileindexmat(ii,sesi) = true;
                                obj.filenames.(obj.searchpaths{sesi,1}){ii}; %#ok<VUNUS>
                                obj.fileindex.(obj.searchpaths{sesi,1})(ii,1) = 1;
                                if obj.verbose; fprintf('%s         \n', lsOut); end
                            else
                                fprintf('\n');
                                warning(['The following files were found for your query: ' Format])
                                warning('Set obj.selectfirstfile = 1 if you want to use the first file');
                                dir(Format)
                                fprintf(1,'\n     ');
                            end
                            
                        case 2 % One file found
                            [folder, NULL, NULL] = fileparts(Format); %#ok<*NASGU>
                            lsOut = fullfile(folder,D.name);
                            obj.fileindexmat(ii,sesi) = true;
                            obj.filenames.(obj.searchpaths{sesi,1}){ii} = lsOut;
                            obj.fileindex.(obj.searchpaths{sesi,1})(ii,1) = 1;
                            
                        case 3
                            % Do nothing
                            
                        case 4 % Select first file from multiple files found
                            D = D(1);
                            [folder, NULL, NULL] = fileparts(Format);
                            lsOut = fullfile(folder,D.name);
                            obj.fileindexmat(ii,sesi) = true;
                            obj.filenames.(obj.searchpaths{sesi,1}){ii} = lsOut;
                            obj.fileindex.(obj.searchpaths{sesi,1})(ii,1) = 1;
                    end
                    
                    if obj.verbose && (action == 2 || action == 4)
                        disp('      ');
                        disp(lsOut);
                    end
                    
                end
                
                fprintf(1,['\nTotal files found: ' num2str(sum(obj.fileindexmat(:,sesi))) '\n\n--------------------------\n\n']);
                if sum(obj.fileindexmat(:,sesi)) == 0
                    warning('Check your file paths and that you have used the correct ID type')
                    disp(['The last path searched for was ' Format])
                    disp('NOTE: In order to select only the first file from a list (such as a list of dicoms), set obj.selectfirstfile = 1')
                end
                if ~isempty(obj.extractfun)
                    obj.extracted.(obj.searchpaths{sesi,1}) = obj.extractfun(obj.filenames.(obj.searchpaths{sesi,1}));
                end
            end
            
            obj.allexist = find(all(obj.fileindexmat,2))';
            
            function [D, Format] = findfile(Format, FirstFile)
                [fol, NULL, NULL] = fileparts(Format); %#ok<SETNU>
                if obj.verbose == true
                    fprintf('Search string %s',Format)
                end
                if ~isempty(strfind(fol,'*')) % use ls to get an exact folder path if folder contains * (slows the script down)
                    try
                        L = ls(Format); % use ls to get file list using * (because it doesn't work with dir if * is in path folder names)
                        L = textscan(L,'%s');
                        L = L{1};
                        
                        if length(L) > 1 % there will only be a > 1 line feed if multiple items found.
                            % if more than one line then either warn user or just pick first file based on value in obj.selectfirstfile
                            if FirstFile == 1
                                L = L(1);
                            else
                                warning('More than one file found. Set obj.selectfirstfile = 1 if you want to use the first file');
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
        end
    end
    methods (Hidden)
        function findprop(obj);     disp(obj); end
        function gt(obj);           disp(obj); end
        function le(obj);           disp(obj); end
        function lt(obj);           disp(obj); end
        function ne(obj);           disp(obj); end
        function notify(obj);       disp(obj); end
        function ge(obj);           disp(obj); end
        function findobj(obj);      disp(obj); end
        function addlistener(obj);  disp(obj); end
        function eq(obj);           disp(obj); end
    end
end