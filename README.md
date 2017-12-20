# queryfs
Generic tool for querying file systems in MATLAB based on a database of study information

This is a simple generic tool for managing and querying filesystems with matlab. It is an advanced search tool which allows the user to construct advanced file system queries based on a spreadsheet of user specified information. This tool was designed with scientific studies in mind but could be used for any purpose. 

Example Usage

The spreadsheet of information on the filesystem could contain a single line for each subject in an analysis, along with the ID tags for the RAW data, which may have been used to save data to the filesystem (often the user ID is not used and must be matched up later).

STUDYID | ID1 | ID2
--- | --- | ---
Sub01 | sub1id1 | sub1id2
Sub01 | sub2id1 | sub2id2
Sub01 | sub3id1 | sub3id2

So that the filesystem is laid out as follows (see example_filesystem in repository root):

    example_filesystem/

        studyids.csv

        Sub01/

            file_sub1id1_56456.mat

            file_sub1id2_84732.mat

        Sub02/

            file_sub2id1_03722.mat

            file_sub2id2_84732.mat

        Sub03/

            file_sub3id1_df456.mat

            file_sub3id2_df421.mat
  
queryfs_filecheck.m takes the spreadsheet of IDs and allows the user to create a file system query based on that ID information. Q.searchpaths is a N x 2 cell array. Column 1 contains the name for a particular search (used later to reference results), while col 2 take the filesystem query. The search path can contain wildcards to match any string in the filename (note the extraneous characters in .mat files above).
 
    Q = [];

    Q.fileinfo = '/root/studyids.csv';

    Q.searchpaths = {

        'matfiles' '/root/<ID1>/<ID2>*.mat'

        };


    Q = queryfs(Q);

    Q now contains informatioin about the files found for that particular query.

files = Q.filenames.matfiles;

Q also contains all the ID information from the spreadsheet, as well as a list of options / defaults

    Q = 

               fileinfo: [1x1 struct] (contains date strings/nums for each file found)
            searchpaths: {'files'  'example_filesystem/<STUDYID>/file_<ID1>*.mat'}
                sublist: [1 2] (index of subjects)
           fileindexmat: [2x1 logical] (logical index of files that exist)
                rootdir: ''
                  debug: 0
        returnfirstfile: 0 (if > 1 file found, then return only the first file, otherwise print warning and empty result)
                verbose: 0 (print files as they are found)
              listfound: 0 (similar to above)
                     ID: [1x1 struct] (struct array containing tabular data from the spreadsheet: IDs etc.)
              filenames: [1x1 struct] (cell arrays of filenames. Struct fields are named according to .searchpaths)
              fileindex: [1x1 struct] (index of files found Struct fields names according to .searchpaths)
              dataflags: [1x1 struct] (not currenly used)
               allexist: [1 2] (indices of rows of .fileinfo that exist 
