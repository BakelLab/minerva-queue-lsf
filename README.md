# minerva-queue-lsf

[TOC]

The minerva-queue repository contains a set of scripts to make it easier to interact with the queueing system on the Minerva cluster. A brief description of each script is provided below and detailed help is also available by running each script with the -h argument.

## Installation ##


1. Get the most recent version of the minerva queue utilities from Bitbucket:

      ```
      git clone git@bitbucket.org:hvbakel/minerva-queue-lsf.git
      ```

2. Add the 'bin' directory with the queue scripts to your PATH environment variable. For example if you cloned the repository in ~/opt, add the  following to your ~/.bashrc file:

   ```
   export PATH="$PATH:~/opt/minerva-queue-lsf/bin"
   ```

3. Optionally, you can symlink the content of the 'www' folder to your minerva web folder (~/www), for example:

   ```
   ln -S /path/to/minerva-queue-lsf/www ~/www/jobs
   ```

   This will allow you to check job status through a web browser on  your computer/phone/tablet, using the url https://<username>.u.hpc.mssm.edu/jobs Note that you will need to set the correct path to your minerva-queue-lsf repository 
   bin folder by copying the content of the file 'config.sample.php' to 'config.php' and editing the path.

Be sure to periodically run 'git pull' in the minerva-queue-lsf directory as the code is updated frequently to stay up to date with the latest queue changes and to add new features.



## Queue scripts ##

#### submitjob

Wrapper script to simplify job submission. Job STDOUT and STDERR are combined and sent to ~/lsf-output or any other dir specified in the SJOB_OUTPUT environment variable. If you use inline awk/perl/matlab commands, submitjob will also properly escape these commands so that they will run in the queue. If no destination queue is specified, submitjob will route the job to the best fitting minerva queue.

Examples;
```
    submitjob 1 -m 12 -c 1  <jobcmd>
      => Request 1 hour of walltime, 12 Gb of (total) memory and 1 cpu on any
         (AMD or intel) node.
    submitjob 24 -m 200 -c 64 <jobcmd>
      => 24 hrs walltime; 200Gb of memory, 64 CPUs on any one node (AMD/intel)
    
    submitjob 24 -m 500 -c 64 -n 2 <jobcmd>
      => 24hrs walltime; 500Gb of memory (across all nodes), 128 CPUs
         on 2 nodes. This will work if your <jobcmd> is cluster-aware,
         like an openmpi run or parallelized make.
    
    submitjob 24 -c 12 -P acc_5 -a mothra <jobcmd>
      => 24 hrs walltime; 12 cpus on a mothra (intel) node in allocation
         acc_5.
    
    submitjob 24 -c 64 -m 200 selfsched <cmdfile>
      => Run a series of commands specified in <cmdfile> using the
         selfsched utility. In the case listed here, selfsched will run
         64 concurrent commands on a single node and exit after all
         commands in <cmdfile> are processed.
```

The submitjob script default job settings can be changed by exporting the   following environment variables in your .bashrc:
    SJOB_OUTPUT    => Location of job output files
    SJOB_CPUS      => Default number of CPUs per node
    SJOB_CPUMEM    => Default memory allocation per CPU in Gb
    SJOB_WALLTIME  => Default walltime in hours
    SJOB_NODES     => Default number of nodes
    SJOB_DEFALLOC  => Default allocation to run jobs in

Default settings will always be overridden by submitjob arguments. Type submitjob -h to get the latest arguments.

```
submitjob [walltime] [-mpcnWqsk] { <command> | selfsched <file> }

<command>
   The command to run on the cluster. Note that any output redirection 
   or pipe symbols must be escaped, i.e. \> or \|

selfsched <file>
  File with commands (one per line) to run through the selfsched utility using
  the resources requested with submitjob
   
Options: 
 walltime <integer>
    The expected run time of the job, measured in hours. Default: 24 
 -c -cpu <integer>
    The number of CPUs required per node. Default: 1
 -n -nodes <integer>
    The number of nodes required. Default: 1
 -m -mem <integer>
    The total amount of memory used by the job in Gb. Default: 2.5 * (No. of CPUs)
 -q -queue <string>
    Target queue. Default: autoselect best queue based on run time and project allocation
 -P -project <string>
    Project allocation to use for this job
 -a -architecture <string>
    Optional comma-separated list of node types; e.g 'mothra,bode' for intel nodes or 'manda' for AMD nodes.
 -s -sem <string>
    Optional name of a file to append job IDs to
 -k -checkpoint <string>
    Automatically checkpoint a job every hour to the checkpoint directory specified here.
 -w -dependency <string>
    Optionally specify a job dependency expression
 -J -jobname <string>
    Optionally specify a job name. Will be set to command name if left empty.
 -g -group <string>
    Optionally specify a host group
 -app <string>
    Specify an application profile. E.g. mpi switch configuration, checkpointing

Job STDERR will be merged with STDOUT and redirected to /hpc/users/vanbah01/lsf-output
Any job exceeding the requested run time and memory limits will be killed automatically.
```



#### jobstatus  

Summary representation of all queued and running jobs. Your jobs will always be listed at the top.

```
jobstatus [-scgh]

Gives a brief summary of all running and queued jobs.

Options:
 -w --webuser
   Specify user when called from web server
 -t --type
   Break down cpu stats by node type
 -h -help
   This help message
```



#### lastjoboutput 

Will always show the output of the most recently finished job(s). Assumes that your job output is in ~/lsf-output (the submitjob default), or any other dir specified in the SJOB_OUTPUT environment variable. Type 'lastjoboutput -h' for more arguments.

```
lastjoboutput [ -n | -i ]
    
Shows the content of the pbs output file for the most recently finished job(s).
    
 Options:
 -n <integer>
   Show output of the last n files, instead of just the last one
 -p <string>
   Specify an alternative path to the job output folder
 -i
   Use job ID rather than file modification time to select most recent jobs
 -help
   This help message
```



#### jobexitstatus

Reports a summary of the exit status for all jobs with output in ~/lsf-output/ or any other dir specified in the SJOB_OUTPUT environment variable. Type 'jobexitstatus -h' for more arguments.

```
jobexitstatus [-pnvr]

Check the exit status of recently finished jobs. Can be used to make sure that
all jobs in a large job submission finished successfully.
    
Options:
 -p -prefix <string>
   Show exit status of jobs whose output file name starts with a specified prefix
 -n -number <integer>
   Show exit status of the n most recently finished jobs (can be used in combination with -p)
 -v -verbose
   Show output for failed jobs
 -s -start <integer>
   Limit verbose output to first s lines. Default: no limit
 -t -tail <integer>
   Limit verbose output to last t lines. Default: no limit
 -r -remove
   Remove the output for failed or missing jobs
 -h -help
   This help message
```



#### nodestatus

Summary representation of node usage. Useful for tailoring jobs to fit the available CPU slots and monitoring jobs as they run.

```
nodestatus 

Displays a graphical summary of node occupancy.
  
Options:
 -u --user
  Only list information for nodes running your jobs
 -help
   This help message
```



#### mailonfinishedjobs

Utility script to monitor your job queue and send an email if there are no more jobs in the queue based on provided parameters.

```
Usage: mailonfinishedjobs [ -J <job-name> -q <queue-name> ] -m <email-address> [ jobid1 ... jobidN ]

Monitor your job queue and send email if there are no more jobs 
in the queue. When run without extra arguments it monitors all queued
jobs. It is also possible to provide extra arguments to filter for
specific jobs by name, ids(s), or queue. Use 'screen' or 'screen -dm' 
(to start in detached mode) to ensure the monitor job remains running
even after your ssh session ends.

Arguments:
 -m <string>
   Email address to send the notification to (required).
 -J <string>
   Monitor jobs with a specific job name (optional)
 -q <queue>
   Monitor jobs in a specific queue (optional)
 -n <string>
   Assign a name to the monitor task (optional)
 -help
   This help message

```

