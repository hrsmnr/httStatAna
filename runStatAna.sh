#!/bin/bash
#SBATCH --mem=4000
#SBATCH --time=600
#SBATCH --partition=medium

echo 'Started at '`date`'...'

STATANADIR="${HOME}/atlas/StatAna/"
ANAFWDIR="${HOME}/atlas/caf2016Jun01/"

INPUT="${ANAFWDIR}/Htautau2015/share/output/bdt_wbinput.root"
WORKSPACE="default"
REGION="HTauTau13TeVLHMVA"
XMLFILE="WorkspaceBuilder/data/HTauTau13TeVCombinationPartSys.xml"
  
CMDNAME=`basename $0`
usage() {
    echo "Usage: $CMDNAME [OPTIONS]"
    echo "  This script is for various statisitcal analyses."
    echo "  By default, runs all WorkspaceBuilder, Significance, NP ranking, FitCrossChecks."
    echo
    echo "Options:"
    echo "  -h, --help"
    echo "  -i, --input FILENAME"
    echo "  -o, --output OUTPUT"
    echo "  -r, --region NAME (StatAnalysis Name in the xml file.)"
    echo "  -x, --xml XMLFILE"
    echo "  -nw, --no_workspace : do not generate workspace by WorkspaceBuilder"
    echo "  -ns, --no_significance : do not compute significance"
    echo "  -nn, --no_npranking : do not make NP Ranking plots"
    echo "  -nf, --no_fitcrosschecks : do not run FitCrossChecks"
    echo "  -w, --workspace : only run WorkspaceBuilder"
    echo "  -s, --significance : only compute significance"
    echo "  -n, --npranking : only make NP Ranking plots"
    echo "  -f, --fitcrosschecks : only run FitCrossChecks"
    echo
    exit 1
}

#Treatment for options
NUMVETO=`expr 0`
wflag='-w'
sflag='-s'
nflag='-n'
fflag='-f'
wonly='false'
sonly='false'
nonly='false'
fonly='false'
for OPT in "$@"
do
    case "$OPT" in
        '-h'|'--help' )
            usage
            exit 1
            ;;
        '-i'|'--input' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "$CMDNAME: option requires an argument -- $1" 1>&2
                exit 1
            fi
            INPUT="$2"
            shift 2
            ;;
        '-o'|'--output' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "$CMDNAME: option requires an argument -- $1" 1>&2
                exit 1
            fi
            WORKSPACE="$2"
            shift 2
            ;;
        '-r'|'--region' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "$CMDNAME: option requires an argument -- $1" 1>&2
                exit 1
            fi
            REGION="$2"
            shift 2
            ;;
        '-x'|'--xml' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "$CMDNAME: option requires an argument -- $1" 1>&2
                exit 1
            fi
            XMLFILE="$2"
            shift 2
            ;;
        '-nw'|'--no_workspace' )
            wflag='0'
            NUMVETO=`expr $NUMVETO + 1`
            shift 1
            ;;
        '-ns'|'--no_significance' )
            sflag='0'
            NUMVETO=`expr $NUMVETO + 1`
            shift 1
            ;;
        '-nn'|'--no_npranking' )
            nflag='0'
            NUMVETO=`expr $NUMVETO + 1`
            shift 1
            ;;
        '-nf'|'--no_fitcrosschecks' )
            fflag='0'
            NUMVETO=`expr $NUMVETO + 1`
            shift 1
            ;;
        '-w'|'--workspace' )
            wonly='true'
            shift 1
            ;;
        '-s'|'--significance' )
            sonly='true'
            shift 1
            ;;
        '-n'|'--npranking' )
            nonly='true'
            shift 1
            ;;
        '-f'|'--fitcrosschecks' )
            fonly='true'
            shift 1
            ;;
        '--'|'-' )
            shift 1
            param+=( "$@" )
            break
            ;;
        -*)
            echo "$CMDNAME: illegal option -- '$(echo $1 | sed 's/^-*//')'" 1>&2
            usage
            exit 1
            ;;
        *)
            if [[ ! -z "$1" ]] && [[ ! "$1" =~ ^-+ ]]; then
                #param=( ${param[@]} "$1" )
                param+=( "$1" )
                shift 1
            fi
            ;;
    esac
done

#Treatment for special options
NUMONLY=`expr 0`
if [ ${wonly} = "true" ]; then NUMONLY=`expr $NUMONLY + 1`; fi
if [ ${sonly} = "true" ]; then NUMONLY=`expr $NUMONLY + 1`; fi
if [ ${nonly} = "true" ]; then NUMONLY=`expr $NUMONLY + 1`; fi
if [ ${fonly} = "true" ]; then NUMONLY=`expr $NUMONLY + 1`; fi
if [ ${NUMONLY} -eq 1 ]; then
    if [ ${wonly} = "true" ]; then 
        wflag='-w'
        sflag='0'
        nflag='0'
        fflag='0'
    fi
    if [ ${sonly} = "true" ]; then 
        wflag='0'
        sflag='-s'
        nflag='0'
        fflag='0'
    fi
    if [ ${nonly} = "true" ]; then 
        wflag='0'
        sflag='0'
        nflag='-n'
        fflag='0'
    fi
    if [ ${fonly} = "true" ]; then 
        wflag='0'
        sflag='0'
        nflag='0'
        fflag='-f'
    fi
elif [ ${NUMONLY} -ne 0  ]; then
    echo "=========================================================="
    echo "Options of -w, -s, -n and -f are alternative. Exitting..."
    echo "=========================================================="
    usage
fi
if [ ${NUMVETO} -ge 1 -a ${NUMONLY} -ge 1 ]; then
    echo "=================================================================================================="
    echo "Options of (-w, -s, -n, -f) and (-nw, -ns, -nn, -nf) cannot be used at the same time. Exitting..."
    echo "=================================================================================================="
    usage
fi

#Starting actual processes
echo "Starting statistical analysis with configurations below..."
echo "Input file  : $INPUT"
echo "Output dir  : $WORKSPACE"
echo "StatAnalysis: $REGION"
echo "Config XML  : $XMLFILE"
echo ""

#Setting up environmental variables
cd ${STATANADIR}
if [ ! -f setup.sh ]; then
    echo 'Error: cannot find setup.sh.'
    echo 'Execute this script where you have WorkspaceBuilder, NuisanceCheck and HbbTools.'
fi
source setup.sh

#Making RooWorkspace by WorkspaceBuilder
if [ ${wflag} = "-w" ]
then
    echo "Generating RooWorkspace..."
    mkdir -p workspaces/${WORKSPACE}
    echo BuildWorkspace -s ${REGION} -v ${WORKSPACE} -x ${XMLFILE} -r ${INPUT} -n WorkspaceBuilder/data/normfactors13TeV.txt -a -p BlindFullWithFloat
    BuildWorkspace -s ${REGION} -v ${WORKSPACE} -x ${XMLFILE} -r ${INPUT} -n WorkspaceBuilder/data/normfactors13TeV.txt -a -p BlindFullWithFloat 2>&1 | tee workspaces/${WORKSPACE}/${WORKSPACE}_WSBuilder.log
    \cp -rp ${INPUT} workspaces/${WORKSPACE}/
fi

#Compute significance
if [ ${sflag} = "-s" ]
then
    echo "Computing significance..."
    cd HbbTools
    time python scripts/getSig.py ${WORKSPACE}/${REGION} 0 125 2>&1 | tee workspaces/${WORKSPACE}/${WORKSPACE}_sig.log
    cd ../
fi

#Making a ranking plot
if [ ${nflag} = "-n" ]
then
    echo "Making NP ranking plot..."
    cd HbbTools
    mkdir -p ascii/${WORKSPACE}
    mkdir -p C-files/${WORKSPACE}
    mkdir -p eps-files/${WORKSPACE}
    mkdir -p pdf-files/${WORKSPACE}
    time python scripts/runNPranking.py ${WORKSPACE}/${REGION} 125 ModelConfig SigXsecOverSM obsData 2>&1 | tee workspaces/${WORKSPACE}/${WORKSPACE}_NPRankingFiles.log
    export WORKDIR="./"
    time python scripts/makeNPrankPlots.py ${WORKSPACE}/${REGION} | tee workspaces/${WORKSPACE}/${WORKSPACE}_NPRankingPlots.log
    \mkdir -p workspaces/${WORKSPACE}/NPRanking
    \cp -rp ascii/${WORKSPACE} workspaces/${WORKSPACE}/NPRanking/
    \cp -rp C-files/${WORKSPACE} workspaces/${WORKSPACE}/NPRanking/
    \cp -rp eps-files/${WORKSPACE} workspaces/${WORKSPACE}/NPRanking/
    \cp -rp pdf-files/${WORKSPACE} workspaces/${WORKSPACE}/NPRanking/
    cd ../
fi

#Making FitCrossChecks plots
if [ ${fflag} = "-f" ]
then
    echo "Running FitCrossChecks..."
    cd NuisanceCheck
    time root -q -b 'runFitCrossChecks.C("../workspaces/'${WORKSPACE}'/combined/125.root","../workspaces/"'${WORKSPACE}'"/fccs/")' 2>&1 | tee ../workspaces/${WORKSPACE}/${WORKSPACE}_FitCrossChecks.log
    time python root2html.py ../workspaces/${WORKSPACE}/fccs/FitCrossChecks.root 2>&1 | tee ../workspaces/${WORKSPACE}/${WORKSPACE}_FitCrossChecksHtml.log
    cd ../
fi

echo 'Finished '`date`'...'
