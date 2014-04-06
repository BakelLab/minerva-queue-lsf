The minerva-queue repository contains a set of scripts to make it easier
to interact with the queueing system on the Minerva cluster. A brief
description of each script is provided below and detailed help is also
available by running each script with the -h argument.

################
# INSTALLATION #
################

1. Get the most recent version of the minerva queue utilities from Bitbucket:

      git clone git@bitbucket.org:hvbakel/minerva-queue-lsf.git

2. Add the 'bin' directory with the queue scripts to your PATH environment
   variable. For example if you cloned the repository in ~/opt, add the 
   following to your ~/.bashrc file:
   
      export PATH="$PATH:~/opt/minerva-queue-lsf/bin"

3. Optionally, you can symlink the content of the 'www' folder to your minerva
   web folder (~/www), for example:

   ln -S /path/to/minerva-queue-lsf/www ~/www/jobs

   This will allow you to check job status through a web browser on 
   your computer/phone/tablet, using the url https://<username>.u.hpc.mssm.edu/jobs
   Note that you will need to set the correct path to your minerva-queue-lsf repository 
   bin folder by copying the content of the file 'config.sample.php' to 'config.php'
   and editing the path.

Be sure to periodically run 'git pull' in the minerva-queue-lsf directory as the
code is updated frequently to stay up to date with the latest queue changes
and to add new features.


#################
# QUEUE SCRIPTS #
#################

submitjob
  Wrapper script to simplify job submission. Job STDOUT and STDERR are 
  combined and sent to ~/pbs-output or any other dir specified in the 
  SJOB_PBS_OUTPUT environment variable. If you use inline awk/perl/matlab 
  commands, submitjob will also properly escape these commands so that 
  they will run in the queue. If no destination queue is specified, 
  submitjob will route the job to the best fitting minerva queue.

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

  The submitjob script default job settings can be changed by exporting the
  following environment variables in your .bashrc:
    SJOB_OUTPUT    => Location of job output files
    SJOB_CPUS      => Default number of CPUs per node
    SJOB_CPUMEM    => Default memory allocation per CPU in Gb
    SJOB_WALLTIME  => Default walltime in hours
    SJOB_NODES     => Default number of nodes
    SJOB_DEFALLOC  => Default allocation to run jobs in
   
   Default settings will always be overridden by submitjob arguments.

jobstatus  
  Summary representation of all queued and running jobs. Your jobs will
  always be listed at the top.
  
lastjoboutput 
  Will always show the output of the most recently finished job(s). 
  Assumes that your job output is in ~/pbs-output (the submitjob default), 
  or any other dir specified in the PBS_OUTPUT environment variable.
  Type 'lastjoboutput -h' for more arguments.

jobexitstatus
  Reports a summary of the exit status for all jobs with output in
  ~/lsf-output/ or any other dir specified in the SJOB_OUTPUT environment
  variable. Type 'jobexitstatus -h' for more arguments.

nodestatus
  Summary representation of node usage. Useful for tailoring jobs to fit 
  the available CPU slots and monitoring jobs as they run.
  * denotes allocated CPUs
  - indicates free CPUs. 
  / indicates allocated CPUs that are not being used
  # indicates CPUs that are in use, but have not been allocated.

