# bpcp

Script to batch process images using CellProfiler and GNU parallel

## Notes
- Requirements
 - `sudo apt-get install parallel -y`
 - `sudo apt-get install python-pip -y`
 - `pip install awscli`
 - `aws configure`
- Before launching, figure out memory requirements of your pipeline (optional)
 - `valgrind --tool=massif --depth=1 --trace-children=yes <cmd>`
- To create RAM disk
 - `mkdir /mnt/ramdisk`
 - `sudo mount -t tmpfs -o size=24576m tmpfs /mnt/ramdisk`
 - On the command line use `-t /mnt/ramdisk`
  - sample usage `./run_analysis_pipeline.sh -d <DATASET> -p <PIPELINE> -t /mnt/ramdisk`
