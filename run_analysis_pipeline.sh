#!/bin/bash

# Before launching, figure out memory requirements of your pipeline
# valgrind --tool=massif --depth=1 --trace-children=yes <cmd>

PROGNAME=`basename $0`

while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -d|--dataset)
    DATASET="$2"
    shift
    ;;
    -p|--pipeline)
    PIPELINE_FILENAME="$2"
    shift
    ;;
    -j)
    NJOBS="$2"
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

NJOBS=${NJOBS:-0}
TMP_DIR="${TMP_DIR:-/tmp}"
echo --------------------------------------------------------------
echo DATASET = ${DATASET}
echo PIPELINE_FILENAME = ${PIPELINE_FILENAME}
echo NJOBS = ${NJOBS} \(not used\)
echo TMP_DIR = ${TMP_DIR}
echo --------------------------------------------------------------
if [[  -z "${DATASET}" ||  -z "${PIPELINE_FILENAME}" ]];
then
    echo Variables not defined.
    exit 1
fi

#DATASET='051816_3661_Q3Q4'
#PIPELINE_FILENAME=analysis_AWS_stable_minimal.cppipe

BASE_DIR='../..'
CP_DOCKER_IMAGE=shntnu/cellprofiler
FILELIST_FILENAME=filelist.txt 
PLATELIST_FILENAME=platelist.txt
WELLLIST_FILENAME=welllist.txt

if [ ! -e $BASE_DIR ];
then
	echo $BASE_DIR not found
	exit 1
fi

mkdir -p ${BASE_DIR}/analysis || exit 1
mkdir -p ${BASE_DIR}/status || exit 1

FILE_LIST_ABS_PATH=`readlink -e /home/ubuntu/bucket/`
FILELIST_DIR=`readlink -e ${BASE_DIR}/filelist`/${DATASET}
FILELIST_FILE=${FILELIST_DIR}/${FILELIST_FILENAME} 
LOG_FILE=`mktemp /tmp/${PROGNAME}_XXXXXX` || exit 1
METADATA_DIR=`readlink -e ${BASE_DIR}/metadata`/${DATASET}
OUTPUT_DIR=`readlink -e ${BASE_DIR}/analysis`/${DATASET}
PIPELINE_DIR=`readlink -e ${BASE_DIR}/pipelines`
PIPELINE_FILE=`readlink -e ${PIPELINE_DIR}/${PIPELINE_FILENAME}`
PLATELIST_FILE=`readlink -e ${METADATA_DIR}/${PLATELIST_FILENAME}`
STATUS_DIR=`readlink -e ${BASE_DIR}/status`/${DATASET}
WELLLIST_FILE=`readlink -e ${METADATA_DIR}/${WELLLIST_FILENAME}`

echo --------------------------------------------------------------
echo FILELIST_FILE  = ${FILELIST_FILE}
echo PIPELINE_FILE  = ${PIPELINE_FILE}
echo PLATELIST_FILE = ${PLATELIST_FILE}
echo WELLLIST_FILE  = ${WELLLIST_FILE}
echo LOG_FILE       = ${LOG_FILE}
echo --------------------------------------------------------------


if [[  -z "${FILELIST_FILE}" ||  -z "${PIPELINE_FILE}" ||  -z "${PLATELIST_FILE}" ||  -z "${WELLLIST_FILE}" ]]; 
then 
    echo Variables not defined.
    exit 1
fi  

mkdir -p $OUTPUT_DIR || exit 1
mkdir -p $STATUS_DIR || exit 1

parallel  \
    --no-run-if-empty \
    --delay 2 \
    --timeout 200% \
    --load 100% \
    --eta \
    --progress \
    --joblog ${LOG_FILE} \
    -a ${PLATELIST_FILE} \
    -a ${WELLLIST_FILE} \
    docker run \
    --volume=${PIPELINE_DIR}:/pipeline_dir \
    --volume=${FILELIST_DIR}:/filelist_dir \
    --volume=${OUTPUT_DIR}:/output_dir \
    --volume=${STATUS_DIR}:/status_dir \
    --volume=${TMP_DIR}:/tmp_dir \
    --volume=${FILE_LIST_ABS_PATH}:${FILE_LIST_ABS_PATH} \
    ${CP_DOCKER_IMAGE} \
    -p /pipeline_dir/${PIPELINE_FILENAME} \
    --file-list=/filelist_dir/${FILELIST_FILENAME} \
    -o /output_dir/ \
    -t /tmp_dir \
    -g Metadata_Plate={1},Metadata_Well={2} \
    -d /status_dir/Plate_{1}_Well_{2}.txt
