# bpcp

Script to batch process images using CellProfiler and GNU parallel

## Notes
- Requirements
 - `sudo apt-get install parallel -y`
 - `sudo apt-get install python-pip -y`
 - `pip install awscli`
 - `aws configure`
- Before launching, figure out memory requirements of your pipeline
 - `valgrind --tool=massif --depth=1 --trace-children=yes <cmd>`
- To create RAM disk
 - `echo mkdir /mnt/ramdisk`
 - `echo sudo mount -t tmpfs -o size=24576m tmpfs /mnt/ramdisk`
 - In the script, assign `TMP_DIR=/mnt/ramdisk`
