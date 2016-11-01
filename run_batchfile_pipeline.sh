#!/bin/bash

PROGNAME=`basename $0`

while [[ $# -gt 0 ]]
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
    -w|--overwrite_batchfile)
    OVERWRITE_BATCHFILE=YES
    ;;
    *)
    echo Unknown option
    ;;
esac
shift
done

FILE_LIST_ABS_PATH="${FILE_LIST_ABS_PATH:-/home/ubuntu/bucket/}"
OVERWRITE_BATCHFILE="${OVERWRITE_BATCHFILE:-NO}"
TMP_DIR="${TMP_DIR:-/tmp}"

echo --------------------------------------------------------------
echo DATASET             = ${DATASET}
echo PIPELINE_FILE       = ${PIPELINE_FILE}
echo TMP_DIR             = ${TMP_DIR}
echo FILE_LIST_ABS_PATH  = ${FILE_LIST_ABS_PATH}
echo OVERWRITE_BATCHFILE = ${OVERWRITE_BATCHFILE}
echo --------------------------------------------------------------

for var in DATASET PIPELINE_FILE TMP_DIR;
do
    if [[  -z "${!var}"  ]];
    then
        echo ${var} not defined.
        exit 1
    fi
done

for var in PIPELINE_FILE;
do
    if [[  -z `readlink -e ${!var}` ]];
    then
        echo ${var}=${!var} not found.
        exit 1
    fi
done

FILE_LIST_ABS_PATH=`readlink -e ${FILE_LIST_ABS_PATH}`
BASE_DIR=`dirname \`dirname ${PIPELINE_FILE}\``
PIPELINE_FILE=`readlink -e ${PIPELINE_FILE}`
PIPELINE_DIR=`dirname ${PIPELINE_FILE}`

#------------------------------------------------------------------
CP_DOCKER_IMAGE=shntnu/cellprofiler
FILELIST_FILENAME=filelist.txt
#------------------------------------------------------------------

mkdir -p ${BASE_DIR}/analysis || exit 1
mkdir -p ${BASE_DIR}/status || exit 1

FILELIST_DIR=`readlink -e ${BASE_DIR}/filelist`/${DATASET}
FILELIST_FILE=`readlink -e ${FILELIST_DIR}/${FILELIST_FILENAME}`
OUTPUT_DIR=`readlink -e ${BASE_DIR}/analysis`/${DATASET}
PIPELINE_FILENAME=`basename ${PIPELINE_FILE}`
STATUS_DIR=`readlink -e ${BASE_DIR}/status`/${DATASET}/

echo --------------------------------------------------------------
echo FILELIST_FILE  = ${FILELIST_FILE}
echo --------------------------------------------------------------

for var in FILELIST_FILE;
do
    if [[  -z "${!var}"  ]];
    then
        echo ${var} not defined.
        exit 1
    fi
done

# Create batch file
if [[ (${OVERWRITE_BATCHFILE} == "YES") ||  (! -e ${OUTPUT_DIR}/Batch_data.h5) ]];
then
    echo Creating batch file ${OUTPUT_DIR}/Batch_data.h5
    docker run \
	--rm \
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
	-t /tmp_dir
else
    echo A batch file already exists, ${OUTPUT_DIR}/Batch_data.h5
fi
