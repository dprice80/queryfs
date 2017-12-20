clc 
clear
close all

addpath /imaging/dp01/toolboxes/query_generic/

Q.SelectFirstFile = 1;
Q.idlist = '/imaging/camcan/LifeBrain/travellingbrain/studyids.csv';
Q.SessionList = {
    'mprage1_s1' '/mridata/cbu/*<CBUID1>*/*/*MPRAGE_32chn/*.dcm'
    'DTI_s1'     '/mridata/cbu/*<CBUID1>*/*/*DTI_64*/*.dcm'
    'DKI_s1'     '/mridata/cbu/*<CBUID1>*/*/*DKI_30*/*.dcm'
    'EPI_s1' '/mridata/cbu/*<CBUID1>*/*/*EPI_Standard*/*.dcm'
    'T2_s1' '/mridata/cbu/*<CBUID1>*/*/*t2_spc*/*.dcm'
    
    'mprage1_s2' '/mridata/cbu/*<CBUID2>*/*/*MPRAGE_32chn/*.dcm'
    'DTI_s2'     '/mridata/cbu/*<CBUID2>*/*/*DTI_64*/*.dcm'
    'DKI_s2'     '/mridata/cbu/*<CBUID2>*/*/*DKI_30*/*.dcm'
    'EPI_s2' '/mridata/cbu/*<CBUID2>*/*/*EPI_Standard*/*.dcm'
    'T2_s2' '/mridata/cbu/*<CBUID2>*/*/*t2_spc*/*.dcm'
    };

Q = query_files(Q);



