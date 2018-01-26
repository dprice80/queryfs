clear q

q = query_files_obj('example_filesystem/id_info.csv');

q.addsearchpath('example1','example_filesystem/<STUDYID>/file_<ID1>_*.mat')
q.addsearchpath('example2','example_filesystem/<STUDYID>/file_<ID2>_*.mat')

q.combine('ID1','ID2')

q.checkfiles