# shell script to copy all the replication code to the replication repo

########################
# SET PATHS
########################

# code source paths
JCODE=~/ddl/justice
JOVERLEAF=~/ddl/justice-overleaf

# data source paths
JDATA=~/iec/justice

# target code and data paths
TARGET=~/ddl/paper-justice
DATATARGET=~/iec/frozen_data/justice/replication

# replication test path
TESTPATH=/scratch/muhtadi/justice

# create target folders that might not exist

########################
# target code folders
mkdir -p $TARGET/b
mkdir -p $TARGET/a
mkdir -p $TARGET/tex

########################
# target data folders
mkdir -p $DATATARGET/raw
mkdir -p $DATATARGET/tmp
mkdir -p $DATATARGET/out

##########################
# COPY CODE FILES

rsync $JCODE/b/build_event_analysis.do $TARGET/b
rsync $JCODE/b/build_lastname_analysis.do $TARGET/b
rsync $JCODE/b/build_rct_analysis.do $TARGET/b
rsync $JCODE/b/clean_delhi_voter_list.do $TARGET/b
rsync $JCODE/b/create_judges_clean.do $TARGET/b
rsync $JCODE/b/create_riots_indicators.do $TARGET/b
rsync $JCODE/b/prep_lit_coefs.do $TARGET/b
rsync $JCODE/b/prep_poi_caste_names.do $TARGET/b
rsync $JCODE/b/prep_poi_data.do $TARGET/b

rsync $JCODE/a/crimes_against_women.do $TARGET/a
rsync $JCODE/a/explore_ambiguity.do $TARGET/a
rsync $JCODE/a/explore_discretion.do $TARGET/a
rsync $JCODE/a/graph_court_size.do $TARGET/a
rsync $JCODE/a/graph_scatter_pub_bias.do $TARGET/a
rsync $JCODE/a/judge_summary.do $TARGET/a
rsync $JCODE/a/matched_balance.do $TARGET/a
rsync $JCODE/a/robustness_checks.do $TARGET/a
rsync $JCODE/a/summary_stats.do $TARGET/a
rsync $JCODE/a/table_balance.do $TARGET/a
rsync $JCODE/a/table_balance_extended.do $TARGET/a
rsync $JCODE/a/table_ingroup_poi.do $TARGET/a
rsync $JCODE/a/table_rct_by_year.do $TARGET/a
rsync $JCODE/a/table_rct_gender.do $TARGET/a
rsync $JCODE/a/table_rct_iv.do $TARGET/a
rsync $JCODE/a/table_rct_lawyers.do $TARGET/a
rsync $JCODE/a/table_rct_religion.do $TARGET/a
rsync $JCODE/a/table_rct_statewise.do $TARGET/a
rsync $JCDOE/a/table_religious_riots.do $TARGET/a
rsync $JCODE/a/table_sample_representativeness.do $TARGET/a
rsync $JCODE/a/table_victim_ramadan.do $TARGET/a
rsync $JCODE/a/test_same_lastname.do $TARGET/a
rsync $JCODE/a/test_same_lastname_app.do $TARGET/a
rsync $JCODE/a/test_same_lastname_unmatched.do $TARGET/a
rsync $JCODE/a/training_sum_stats.do $TARGET/a
rsync $JCODE/a/women_analysis.do $TARGET/a

rsync $JCODE/justice_programs.do $TARGET


###################################################3
# copy all datafiles needed for replication

rsync $JDATA/cases_clean_2010.dta $DATATARGET/raw
rsync $JDATA/cases_clean_2010.dta $DATATARGET/raw
rsync $JDATA/cases_clean_2011.dta $DATATARGET/raw
rsync $JDATA/cases_clean_2012.dta $DATATARGET/raw
rsync $JDATA/cases_clean_2013.dta $DATATARGET/raw
rsync $JDATA/cases_clean_2014.dta $DATATARGET/raw
rsync $JDATA/cases_clean_2015.dta $DATATARGET/raw
rsync $JDATA/cases_clean_2016.dta $DATATARGET/raw
rsync $JDATA/cases_clean_2017.dta $DATATARGET/raw
rsync $JDATA/cases_clean_2018.dta $DATATARGET/raw
rsync $JDATA/cases_all_years.dta $DATATARGET/raw
rsync $JDATA/judges_clean.dta $DATATARGET/raw
rsync $JDATA/keys/disp_name_key.dta $DATATARGET/raw
rsync $JDATA/classification/pooled_names_clean_appended.dta $DATATARGET/raw
rsync $JDATA/lit_coefs.dta $DATATARGET/raw
rsync $JDATA/justice_analysis.dta $DATATARGET/raw
rsync $JDATA/keys/cases_district_key.dta $DATATARGET/raw
rsync $JDATA/raw/ACLED_India_violence_2005-2023.csv $DATATARGET/raw
rsync $JDATA/names/delhi_voter_list_unclean.dta $DATATARGET/raw
rsync $JDATA/names/railway_names_unclean.dta $DATATARGET/raw
rsync $JDATA/justice_same_names.dta $DATATARGET/raw
rsync $JDATA/norms/1990/clean/poi_master.dta $DATATARGET/raw
rsync $JDATA/keys/cases_state_key.dta $DATATARGET/raw


# tex template files
rsync $jcode/tex/*tpl* $TARGET/tex


########################################################
# clone the frozen data folder to the polaris test path
# rm -rf $TESTPATH
rsync -r $DATATARGET $TESTPATH

#############
# tex files #
#############

rsync $JOVERLEAF/main.tex $TARGET/tex

# Bib 
# cp ~/ddl/tools/tex/master.bib ~/ddl/paper-anr-mobility-india/tex/

# elliott.bib, india.bib

# NOTE WE DO NOT COPY THE MAIN PAPER TEX FILE AUTOMATICALLY, AS THIS GETS CHANGED
# IN THE REPLICATION REPO (e.g. new paths, input locations, etc.)

######################################
# export data packet to Google Drive #
######################################

# switch to the frozen data folder
# cd ~/iec/frozen_data/mobility
cd $DATATARGET

# zip all the core data files
# mkdir /scratch/pn
# zip -r /scratch/pn/mobility_packet.zip *

# unzip it into /scratch/pn/mobility for testing
# rm -rf /scratch/pn/mobility
# cd /scratch/pn/mobility
# unzip ../mobility_packet.zip

# rclone it to Google Drive
# rclone copy /scratch/pn/mobility_packet.zip ddl_full:data/public-repos/data-mobility/

echo "Finished copying content."
