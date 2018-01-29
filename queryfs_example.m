clear q
q = queryfs('example_filesystem/id_info.csv');
q.addsearchpath('example1','example_filesystem/<STUDYID>/file_<ID1|ID2>_*.mat');
q.checkfiles

