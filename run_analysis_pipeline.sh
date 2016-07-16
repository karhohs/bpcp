#!/bin/bash

programname=$0

# function usage {
#     echo "usage:$programname <plate-id> <group>"
#     exit 1
# }

# if [ $# -ne 2 ]; then
#     (>&2 echo "Incorrect number of arguments")
#     exit
# fi

# plate_id=$1
# group=$2
# subdir=`echo $group| tr "," "_"|tr "=" "_"|sed "s/Metadata_//g"`
# domain=`hostname -d`

# project_dir=${HOME}/efs/2015_10_05_DrugRepurposing_AravindSubramanian_GolubLab_Broad/2016_04_01_a549_48hr_batch1
# loaddata_dir=$project_dir/load_data_csv/$plate_id/

# if [ ! -e $loaddata_csv ]; then
#     (>&2 echo "$loaddata_csv does not exist. Exiting.")
#     exit
# fi

# pipeline_dir=$project_dir/pipelines/cellpainting_v2
# output_dir=$project_dir/analysis/$plate_id

# mkdir -p $output_dir

dataset='set_1'
pipeline_dir=`readlink -e ../../../pipelines`
filelist_dir=`readlink -e ../../../filelist`/${dataset}
output_dir=`readlink -e ../../../analysis`/${dataset}
done_dir=`readlink -e ../../../done`/${dataset}
tmp_dir=/tmp
mkdir -p $output_dir
mkdir -p $done_dir

pipeline_file=analysis_AWS_stable.cppipe
group='Metadata_Plate=160519140001,Metadata_Well=A01'
group_tag=`echo $group|tr ',=' '_'`
plate_list='../../../metadata/plateid_051816_3661_Q3Q4.txt'
well_list='../../../metadata/multiwellplate96.txt'

parallel -j 2 \
    --no-run-if-empty \
    --delay .1 \
    --timeout 200% \
    --load 100% \
    --eta \
    --progress \
    --joblog /tmp/cpbatch.log \
    -a ${plate_list} \
    -a ${well_list} \
    docker run \
    --volume=${pipeline_dir}:/pipeline_dir \
    --volume=${filelist_dir}:/filelist_dir \
    --volume=${output_dir}:/output_dir \
    --volume=${done_dir}:/done_dir \
    --volume=${tmp_dir}:/tmp_dir \
    --volume=/home/ubuntu/bucket/:/home/ubuntu/bucket \
    shntnu/cellprofiler \
    -p /pipeline_dir/${pipeline_file} \
    --file-list=/filelist_dir/filelist.txt \
    -o /output_dir/ \
    -t /tmp_dir \
    -g Metadata_Plate={1},Metadata_Well={2} \
    -d /done_dir/Plate_{1}_Well_{2}.txt

