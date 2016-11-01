# bpcp
*bpcp* exists to batch process images using [CellProfiler](https://github.com/CellProfiler/CellProfiler) and GNU parallel on a Linux operating system.

# bpcp on AWS
*bpcp* can be run on a Linux Amazon Machine Image (AMI) assigned to an Amazon Elastic Compute Cloud (EC2) instance. Many EC2 instances contain numerous *vCPU* that can each serve a CellProfiler process. *bpcp* manages the processing of an image dataset across the vCPU of EC2 instances, delivering the performance of a small computer cluster.

AWS provides an attractive set of services that can manage an entire CellProfiler workflow, but to document the setup of an AWS workflow is beyond the scope of this documentation (see [cellprofiler.org](http://cellprofiler.org) for more information). *bpcp* is focused on the mechanics of running CellProfiler in parallel to batch process a large dataset, e.g. image data derived from a few 384-well plates. For very large datasets, e.g. a large image-based drug screen using hundreds of multi-well plates, consider utilizing [Distributed-CellProfiler](https://github.com/jccaicedo/Distributed-CellProfiler) for AWS.

## Configuring an AMI (for the first time)
By default, an AMI will be a fresh install of Linux, available in several flavors. After configuring this initial AMI, a snapshot can be taken to create your own customized AMI that does not require the following steps to be repeated. It is assumed that an AWS account has already been configured and an Identity and Access Management (IAM) user has been created along with the necessary security credentials.

## Log in to an instance running your AMI
1. Open the EC2 Dashboard from https://console.aws.amazon.com
1. Launch an instance or spot instance.
 - choose a small instance type, such as a *t2.nano*, because minimal resources are required for the initial setup.
1. Configure the instance such that it can be connected to via SSH.
1. Once the instance is created it will appear among a list of all instances in the *INSTANCES > Instances* menu on the EC2 Dashboard.

## Requirements


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
