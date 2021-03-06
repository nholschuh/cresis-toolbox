% script run_all
%
% Used by run_all scripts to select parameter spreadsheets to run

param_fns = {};
% param_fns{end+1} = 'accum_param_2015_Antarctica_Ground.xls';
% param_fns{end+1} = 'accum_param_2018_Antarctica_TObas.xls';
% param_fns{end+1} = 'accum_param_2019_Antarctica_TObas.xls';
% param_fns{end+1} = 'rds_param_1993_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_1995_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_1996_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_1997_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_1998_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_1999_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_2001_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_2002_Antarctica_P3chile.xls'; % May not work
% param_fns{end+1} = 'rds_param_2002_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_2003_Greenland_P3.xls'; % May not work
% param_fns{end+1} = 'rds_param_2004_Antarctica_P3chile.xls'; % May not work
% param_fns{end+1} = 'rds_param_2005_Greenland_TO.xls'; % May not work
% param_fns{end+1} = 'rds_param_2006_Greenland_TO.xls';
% param_fns{end+1} = 'rds_param_2007_Greenland_P3.xls'; % May not work
% param_fns{end+1} = 'rds_param_2008_Greenland_Ground.xls';
% param_fns{end+1} = 'rds_param_2008_Greenland_TO.xls';
% param_fns{end+1} = 'rds_param_2009_Antarctica_DC8.xls';
% param_fns{end+1} = 'rds_param_2009_Antarctica_TO.xls';
% param_fns{end+1} = 'rds_param_2009_Greenland_TO.xls';
% param_fns{end+1} = 'rds_param_2009_Greenland_TO_wise.xls';
% param_fns{end+1} = 'rds_param_2010_Antarctica_DC8.xls';
% param_fns{end+1} = 'rds_param_2010_Greenland_DC8.xls';
% param_fns{end+1} = 'rds_param_2010_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_2010_Greenland_TO_wise.xls';
% param_fns{end+1} = 'rds_param_2011_Antarctica_DC8.xls';
% param_fns{end+1} = 'rds_param_2011_Antarctica_TO.xls';
% param_fns{end+1} = 'rds_param_2011_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_2011_Greenland_TO.xls';
% param_fns{end+1} = 'rds_param_2012_Antarctica_DC8.xls';
% param_fns{end+1} = 'rds_param_2012_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_2013_Antarctica_Basler.xls';
% param_fns{end+1} = 'rds_param_2013_Antarctica_P3.xls';
% param_fns{end+1} = 'rds_param_2013_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_2014_Antarctica_DC8.xls';
% param_fns{end+1} = 'rds_param_2014_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_2015_Greenland_C130.xls';
% param_fns{end+1} = 'rds_param_2016_Antarctica_DC8.xls';
% param_fns{end+1} = 'rds_param_2016_Greenland_G1XB.xls';
% param_fns{end+1} = 'rds_param_2016_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_2016_Greenland_Polar6.xls';
% param_fns{end+1} = 'rds_param_2016_Greenland_TOdtu.xls';
% param_fns{end+1} = 'rds_param_2017_Antarctica_Basler.xls';
% param_fns{end+1} = 'rds_param_2017_Antarctica_P3.xls';
% param_fns{end+1} = 'rds_param_2017_Antarctica_Polar6.xls';
% param_fns{end+1} = 'rds_param_2017_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_2018_Antarctica_DC8.xls';
param_fns{end+1} = 'rds_param_2018_Antarctica_Ground.xls';
% param_fns{end+1} = 'rds_param_2018_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_2018_Greenland_Polar6.xls';
% param_fns{end+1} = 'rds_param_2019_Greenland_P3.xls';
% param_fns{end+1} = 'rds_param_2019_Antarctica_Ground.xls';
% param_fns{end+1} = 'rds_param_2019_Antarctica_GV.xls';
% param_fns{end+1} = 'snow_param_2009_Antarctica_DC8.xls';
% param_fns{end+1} = 'snow_param_2009_Greenland_P3.xls';
% param_fns{end+1} = 'snow_param_2010_Antarctica_DC8.xls';
% param_fns{end+1} = 'snow_param_2010_Greenland_DC8.xls';
% param_fns{end+1} = 'snow_param_2010_Greenland_P3.xls';
% param_fns{end+1} = 'snow_param_2011_Antarctica_DC8.xls';
% param_fns{end+1} = 'snow_param_2011_Greenland_P3.xls';
% param_fns{end+1} = 'snow_param_2012_Antarctica_DC8.xls';
% param_fns{end+1} = 'snow_param_2012_Greenland_P3.xls';
% param_fns{end+1} = 'snow_param_2013_Greenland_P3.xls';
% param_fns{end+1} = 'snow_param_2013_Greenland_Ground.xls';
% param_fns{end+1} = 'snow_param_2013_Antarctica_P3.xls';
% param_fns{end+1} = 'snow_param_2013_Antarctica_Basler.xls';
% param_fns{end+1} = 'snow_param_2014_Alaska_TOnrl.xls';
% param_fns{end+1} = 'snow_param_2014_Antarctica_DC8.xls';
% param_fns{end+1} = 'snow_param_2014_Greenland_P3.xls';
% param_fns{end+1} = 'snow_param_2015_Alaska_TOnrl.xls';
% param_fns{end+1} = 'snow_param_2015_Greenland_C130.xls';
% param_fns{end+1} = 'snow_param_2016_Alaska_TOnrl.xls';
% param_fns{end+1} = 'snow_param_2016_Greenland_P3.xls';
% param_fns{end+1} = 'snow_param_2016_Antarctica_DC8.xls';
% param_fns{end+1} = 'snow_param_2016_Greenland_Polar6.xls';
% param_fns{end+1} = 'snow_param_2017_Greenland_P3.xls';
% param_fns{end+1} = 'snow_param_2017_Antarctica_P3.xls';
% param_fns{end+1} = 'snow_param_2018_Greenland_P3.xls';
% param_fns{end+1} = 'snow_param_2018_Alaska_SO.xls';
% param_fns{end+1} = 'snow_param_2018_Antarctica_DC8.xls';
% param_fns{end+1} = 'snow_param_2019_Greenland_P3.xls';
% param_fns{end+1} = 'snow_param_2019_Arctic_GV.xls';
% param_fns{end+1} = 'snow_param_2019_Antarctica_GV.xls';
