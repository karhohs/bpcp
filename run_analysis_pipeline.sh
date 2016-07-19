#!/bin/bash


while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -d|--dataset)
    DATASET="$2"
    shift
    ;;
    -p|--pipeline)
    PIPELINE_FILE="$2"
    shift
    ;;
    -t|--tmpdir)
    TMP_DIR="$2"
    shift
    ;;
    *)
    # unknown option
    ;;
esac
shift
done

TMP_DIR="${TMP_DIR:-/tmp}"
FILE_LIST_ABS_PATH="${FILE_LIST_ABS_PATH:-/home/ubuntu/bucket/}"

echo --------------------------------------------------------------
echo DATASET            = ${DATASET}
echo PIPELINE_FILE      = ${PIPELINE_FILE}
echo TMP_DIR            = ${TMP_DIR}
echo FILE_LIST_ABS_PATH = ${FILE_LIST_ABS_PATH}
echo --------------------------------------------------------------

for var in DATASET PIPELINE_FILE TMP_DIR;
do 
    if [[  -z "${!var}"  ]];
    then
        echo ${var} not defined.
        exit 1
    fi
done

for var in PIPELINE_FILE FILE_LIST_ABS_PATH;
do 
    if [[  -z `readlink -e ${!var}` ]];
    then
        echo ${var}=${!var} not found.
        exit 1
    fi
done

PIPELINE_FILE=`readlink -e ${PIPELINE_FILE}`
FILE_LIST_ABS_PATH=`readlink -e ${FILE_LIST_ABS_PATH}`

exit 1

#------------------------------------------------------------------
CP_DOCKER_IMAGE=shntnu/cellprofiler
FILELIST_FILENAME=filelist.txt 
PLATELIST_FILENAME=platelist.txt
WELLLIST_FILENAME=welllist.txt
#------------------------------------------------------------------

PIPELINE_DIR=`dirname ${PIPELINE_FILE}`
BASE_DIR=`dirname $PIPELINE_DIR`

mkdir -p ${BASE_DIR}/analysis || exit 1
mkdir -p ${BASE_DIR}/log || exit 1
mkdir -p ${BASE_DIR}/status || exit 1

FILELIST_DIR=`readlink -e ${BASE_DIR}/filelist`/${DATASET}
FILELIST_FILE=`readlink -e ${FILELIST_DIR}/${FILELIST_FILENAME}`
METADATA_DIR=`readlink -e ${BASE_DIR}/metadata`/${DATASET}
OUTPUT_DIR=`readlink -e ${BASE_DIR}/analysis`/${DATASET}
PIPELINE_FILENAME=`basename ${PIPELINE_FILE}`
PLATELIST_FILE=`readlink -e ${METADATA_DIR}/${PLATELIST_FILENAME}`
STATUS_DIR=`readlink -e ${BASE_DIR}/status`/${DATASET}/
LOG_DIR=`readlink -e ${BASE_DIR}/log`/${DATASET}
mkdir -p $LOG_DIR || exit 1
DATE=$(date +"%Y%m%d%H%M%S")
LOG_FILE=`mktemp --tmpdir=${LOG_DIR} ${PROGNAME}_${DATE}_XXXXXX` || exit 1
WELLLIST_FILE=`readlink -e ${METADATA_DIR}/${WELLLIST_FILENAME}`

echo --------------------------------------------------------------
echo FILELIST_FILE  = ${FILELIST_FILE}
echo PLATELIST_FILE = ${PLATELIST_FILE}
echo WELLLIST_FILE  = ${WELLLIST_FILE}
echo LOG_FILE       = ${LOG_FILE}
echo --------------------------------------------------------------

if [[  -z "${FILELIST_FILE}" ||  -z "${PLATELIST_FILE}" ||  -z "${WELLLIST_FILE}" ]]; 
then 
    echo Variables not defined.
    exit 1
fi  

mkdir -p $OUTPUT_DIR || exit 1
mkdir -p $STATUS_DIR || exit 1

# Create a log group:
# Requirements: 
# - sudo apt-get install parallel -y
# - sudo apt-get install python-pip -y
# - pip install awscli
# Configure AWS:
# - aws configure 

type aws >/dev/null 2>&1 || { echo >&2 "aws-cli not installed.  Aborting."; exit 1; }

if [ `aws logs describe-log-groups|grep "\"logGroupName\": \"$DATASET\""|wc -l` -ne 1 ]; 
then 
    echo aws-log-group ${DATASET} does not exist. 
    echo To create log group:
    echo aws logs create-log-group --log-group-name ${DATASET}
    exit 1
fi;

SETS_FILE=${LOG_DIR}/sets.txt

parallel -a ${PLATELIST_FILE} -a ${WELLLIST_FILE} echo {1} {2}|sort > ${SETS_FILE}.1
find ${STATUS_DIR} -name "*.txt" | xargs grep -l Complete |xargs -n 1 basename|cut -d"_" -f 2,4|cut -d"." -f1|tr '_' ' '|sort > ${SETS_FILE}.2
#comm -23 ${SETS_FILE}.1 ${SETS_FILE}.2 |tr ' ' '\t' |head -n 3 > ${SETS_FILE}
comm -23 ${SETS_FILE}.1 ${SETS_FILE}.2 |tr ' ' '\t' > ${SETS_FILE}

parallel  \
    --no-run-if-empty \
    --delay .1 \
    --max-procs -1 \
    --timeout 200% \
    --load 100% \
    --eta \
    --progress \
    --joblog ${LOG_FILE} \
    -a ${SETS_FILE} \
    --colsep '\t' \
    docker run \
    --rm \
    --volume=${PIPELINE_DIR}:/pipeline_dir \
    --volume=${FILELIST_DIR}:/filelist_dir \
    --volume=${OUTPUT_DIR}:/output_dir \
    --volume=${STATUS_DIR}:/status_dir \
    --volume=${TMP_DIR}:/tmp_dir \
    --volume=${FILE_LIST_ABS_PATH}:${FILE_LIST_ABS_PATH} \
    --log-driver=awslogs \
    --log-opt awslogs-group=${DATASET} \
    --log-opt awslogs-stream=Plate_{1}_Well_{2} \
    ${CP_DOCKER_IMAGE} \
    -p /pipeline_dir/${PIPELINE_FILENAME} \
    --file-list=/filelist_dir/${FILELIST_FILENAME} \
    -o /output_dir/ \
    -t /tmp_dir \
    -g Metadata_Plate={1},Metadata_Well={2} \
    -d /status_dir/Plate_{1}_Well_{2}.txt
