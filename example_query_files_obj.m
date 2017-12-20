clc 
clear
close all

addpath /imaging/dp01/toolboxes/query_generic/
addpath /home/dp01/matlab/lib

Q = query_files_obj;

Q.idlist = '/imaging/camcan/LifeBrain/travellingbrain/studyids.csv';
Q.SessionList = {
    'mprage1' '/mridata/cbu/*<CBUID>*/*/*MPRAGE_32chn/*.dcm'
    };
Q.SelectFirstFile = true;

Q.checkfiles()

Q.FileNames.mprage1
