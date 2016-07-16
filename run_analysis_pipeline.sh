#!/bin/bash
PROGNAME=`basename $0`

# while [[ $# -gt 1 ]]
# do
# key="$1"

# case $key in
#     -e|--extension)
#     EXTENSION="$2"
#     shift 
#     ;;
#     -s|--searchpath)
#     SEARCHPATH="$2"
#     shift 
#     ;;
#     -l|--lib)
#     LIBPATH="$2"
#     shift 
#     ;;
#     --default)
#     DEFAULT=YES
#     ;;
#     *)
#             # unknown option
#     ;;
# esac
# shift 
# done



BASE_DIR='../..'
CP_DOCKER_IMAGE=shntnu/cellprofiler
DATASET='set_1'
FILELIST_FILENAME=filelist.txt 
PIPELINE_FILENAME=analysis_AWS_stable_minimal.cppipe
PLATELIST_FILENAME=plateid_051816_3661_Q3Q4.txt
WELLLIST_FILENAME=multiwellplate96.txt

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
TMP_DIR="${TMP_DIR:-/tmp}"
WELLLIST_FILE=`readlink -e ${METADATA_DIR}/${WELLLIST_FILENAME}`

if [ ! -z "${FILELIST_FILE}" || ! -z "${PIPELINE_FILE}" || ! -z "${PLATELIST_FILE}" || ! -z "${WELLLIST_FILE}" ]; 
then 
    echo Variables not defined.
    exit 1
fi  


mkdir -p $OUTPUT_DIR
mkdir -p $STATUS_DIR

echo \
parallel -j 2 \
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

