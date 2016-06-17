#!/bin/bash
#########################################################################################
# Make sure you setup proper CERN Username for svn.cern.ch before execute this script.
# (Otherwise you would be required to type password several times.)
# (Mistyping of your password might lead you to unknown state.)
# There sould be some tricks in ~/.ssh/config as below...
# --------------------------------
# Host svn.cern.ch
# User [CERNUSER]
# GSSAPITrustDns yes
# GSSAPIAuthentication yes
# GSSAPIDelegateCredentials yes
# --------------------------------
#########################################################################################
CERNUSER='hirose'
if [ ${USER} != "mh1160" -o ${USER} = "hirose" ]; then
   if [ ${CERNUSER} = 'hirose' ]; then
      echo 'You are not user hirose!!'
      echo 'Please modify CERNUSER in this script to your CERN username...'
      echo 'Also make sure you setup kerberos authentication for svn.cern.ch.'
      echo '(see comments at the beginnig of this script.)'
      echo 'Exitting...'
   fi
fi
kinit ${CERNUSER}@CERN.CH

svn co svn+ssh://svn.cern.ch/reps/atlasoff/PhysicsAnalysis/D3PDTools/RootCore/tags/RootCore-00-04-57 RootCore
##################################################################################################
# You have to replace nullptr by NULL in RootCore/scripts/load_packages.C:L31 since we use ROOT5
sed -i -e "s/nullptr/NULL/g" RootCore/scripts/load_packages.C
##################################################################################################
export ATLAS_LOCAL_ROOT_BASE=/cvmfs/atlas.cern.ch/repo/ATLASLocalRootBase
source $ATLAS_LOCAL_ROOT_BASE/user/atlasLocalSetup.sh
localSetupROOT 5.34.32-HiggsComb-p1-x86_64-slc6-gcc48-opt
localSetupBoost boost-1.47.0-python2.6-x86_64-slc5-gcc43
source RootCore/scripts/setup.sh
svn co svn+ssh://svn.cern.ch/reps/atlasphys-hsg4/Physics/Higgs/HSG4/software/Statistics/WorkspaceBuilder/trunk WorkspaceBuilder
rc find_packages
rc compile
svn co -r 236154 svn+ssh://svn.cern.ch/reps/atlasphys-hsg5/Physics/Higgs/HSG5/Limits/InputPreparation/WSMaker/trunk HbbTools
cd HbbTools
make -j8
cd ../
svn co svn+ssh://svn.cern.ch/reps/atlasphys/Physics/StatForum/NuisanceCheck/tags/NuisanceCheck-00-00-05/ NuisanceCheck

###############################################################################
# Below command generates the macro to run FitCrossChecks
###############################################################################
echo '#include<iostream>
#include"TROOT.h"

Int_t runFitCrossChecks(std::string infile, std::string outdir){
  std::cout<<"==================================================================="<<std::endl;
  std::cout<<"Making FitCrossChecks plots..."<<std::endl;
  std::cout<<"Infile: "<<infile<<std::endl;
  std::cout<<"Outdir: "<<outdir<<std::endl;
  std::cout<<"==================================================================="<<std::endl;
  gROOT->ProcessLine(".L FitCrossCheckForLimits.C+");
  LimitCrossCheck::PlotFitCrossChecks(infile.c_str(),outdir.c_str());
  return 0;
}' > NuisanceCheck/runFitCrossChecks.C

###############################################################################
# Below command generates setup.sh
###############################################################################
echo 'export ATLAS_LOCAL_ROOT_BASE=/cvmfs/atlas.cern.ch/repo/ATLASLocalRootBase
source ${ATLAS_LOCAL_ROOT_BASE}/user/atlasLocalSetup.sh
localSetupROOT 5.34.32-HiggsComb-p1-x86_64-slc6-gcc48-opt
localSetupBoost boost-1.47.0-python2.6-x86_64-slc5-gcc43
source RootCore/scripts/setup.sh
' > setup.sh

###############################################################################
# Below command generates README
###############################################################################
echo 'This directory provides all tools for statistical analysis.
All analyses are based on RooWorkspace built by WorkspaceBuilder.
Then, we can compute significance, check nuisance parameter (NP) ranking,
and check results of the profiling likelihood fit by FitCrossChecks.

First of all you need to setup some environmental variables by ...

$source setup.sh

To performe all these analysis chain, you can simply execute runStatAna.sh as below.

$runStatAna.sh -i [input file] -o [output directory]
[input file] is the workspace builder input file.
[output directory] is the directory to store all results in "workspaces" directory.

More options can be seen by 

$runStatAna.sh -h

This script can be directly submitted to the batch job system by slurm as below.

$sbatch ./runStatAna.sh -i [input file] -o [output directory]

Bug report, wishlist can be sent to ...
Minoru Hirose (minoru.hirose@cern.ch)
' > README

echo ''
echo 'Install successfully finished.'
echo '----------------------------------------------------------------------------------------'
echo 'You have to modify ANAFWDIR to point your analysis framework directory for automatition.'
echo '----------------------------------------------------------------------------------------'
