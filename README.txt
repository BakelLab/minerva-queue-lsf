#########################
# QUEUE UTILITY SCRIPTS #
#########################

The minerva-queue repository contains a set of scripts to make it easier
to interact with the queueing system on the Minerva cluster. A brief
description of each script is provided below and detailed help is also
available by running each script with the -h argument.

submitjob
  job submission script that takes care of wrapping most of the qsub
  arguments. Job STDOUT and STDERR are combined and sent to ~/pbs-output
  or any other dir specified in the PBS_OUTPUT environment variable.
  If you use inline awk/perl/matlab commands, submitjob will also 
  properly escape these commands so that they will run in the queue.
  If no destination queue is specified, submitjob will route the job to 
  the best fitting minerva queue.

  Examples;
    submitjob 1 -m 12 -c 1  <jobcmd>
      => Request 1 hour of walltime, 12 Gb of (total) memory and 1 cpu

    submitjob 24 -m 200 -c 64 <jobcmd>
      => 24 hrs walltime; 200Gb of memory, 46 CPUs on one node

    submitjob 24 -m 500 -c 64 -n 2 <jobcmd>
      => 24hrs walltime; 500Gb of memory (across all nodes), 128 CPUs
         on 2 nodes. This will work if your <jobcmd> is cluster-aware,
         like an openmpi run or parallelized make.
         
    submitjob 24 -c 64 -m 200 selfsched <cmdfile>
      => Run a series of commands specified in <cmdfile> using the
         selfsched utility. In the case listed here, selfsched will run
         64 concurrent commands on a single node and exit after all
         commands in <cmdfile> are processed.

jobstatus  
  Summary representation of all queued and running jobs. Your jobs will
  always be listed at the top. Type 'jobstatus -p' or 'jobstatus -g' to 
  instead get a summary of CPUs or GPUs, respectively.
  
nodestatus
  Summary representation of node usage. Useful for tailoring jobs to fit 
  the available CPU slots and monitoring jobs as they run.
  * denotes allocated CPUs
  - indicates free CPUs. 
  / indicates allocated CPUs that are not being used
  # indicates CPUs that are in use, but have not been allocated.
    
lastjoboutput 
  Will always show the output of the most recently finished job(s). 
  Assumes that your job output is in ~/pbs-output (the submitjob default), 
  or any other dir specified in the PBS_OUTPUT environment variable.

deletejobs
  Delete your running and/or queued jobs based on a set of criteria such
  as job name, state, queue, or job identifier range. Use multiple
  options together to narrow down your selection. The script will ask for 
  confirmation before it does anything.
  
jobexitstatus
  Reports a summary of the exit status for all jobs with output in
  ~/pbs-output/ or any other dir specified in the PBS_OUTPUT environment
  variable. Note that this functionality requires that the torque prologue
  and epilogue scripts are installed in your home dir (see INSTALL.txt).
  
waitforjobs
  When submitting jobs with 'submitjob' it is possible to write the job
  ids to a file and pass this file to 'waitforjobs'. This script will
  then wait for these jobs to finish. It can be used as part of a shell
  script to allow for a batch of jobs to finish before doing a new
  submission.
  
cache-qstat
  Admin script to wrap and add caching functionality to the default
  qstat command. Can be used to prevent clients from flooding the torque
  server with requests.

runonallnodes
  Admin script to run a command on all cluster nodes. Useful to get an
  overview of disk stats etc. Example: runonallnodes 'df -h | grep sda3'
