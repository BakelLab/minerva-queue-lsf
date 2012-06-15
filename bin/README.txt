#########################
# QUEUE UTILITY SCRIPTS #
#########################

submitjob
  job submission script that takes care of wrapping most of the qsub
  arguments. Job STDOUT and STDERR are combined and sent to ~/pbs-output.
  If you use a lot of inline awk/perl/matlab commands it will also
  properly escape these commands so that they will run in the queue.
  If no queue is specified, submitjob will route the job to the best
  fitting minerva queue.

  Examples;
    submitjob 1 -m 12 -c 1  <jobcmd>
      => Request 1 hour of walltime, 12 Gb of (total) memory and 1 cpu

    submitjob 24 -m 200 -c 64 <jobcmd>
      => 24 hrs walltime; 200Gb of memory, 46 CPUs on one node

    submitjob 24 -m 500 -c 64 -n 2 <jobcmd>
      => 24hrs walltime; 500Gb of memory (across all nodes), 128 CPUs
         on 2 nodes. This will work if your <jobcmd> is cluster-aware,
         like an openmpi run or parallelized make.

jobstatus  
  Summary representation of all queued and running jobs. Your jobs will
  always be listed at the top. Type 'jobstatus -p' to get a summary
  of CPUs in use instead.
  
nodestatus
  Summary representation of node usage. This is useful for tailoring 
  jobs to fit the available CPU slots.
  * denotes allocated CPUs
  - indicates free CPUs. 
  / indicates allocated CPUs that are not being used
  # indicates CPUs that are in use, but have not been allocated.
    
lastjoboutput 
  Will always show the output of the most recently finished job. Assumes 
  that your job output is in ~/pbs-output (the submitjob default), or
  any other dir specified in the PBS_OUTPUT environment variable.

deleteallmyjobs
  Does exactly that. Great way to quickly terminate a job submission 
  gone wrong. It will ask for confirmation before it does anything.

torque.epilogue.sh
  Epilogue script for torque that includes a summary of resources used
  and job exit status in the job output. This script can be attached to
  any job submission by adding the full path to the resource string (-l)
  "epilogue=/path/to/torque.epilogue.sh". If you copy this file to your
  home dir and rename it to ".torque.epilogue.sh", it will be picked up
  by the submitjob script automatically. NOTE: The script must have 
  permissions set to 700, otherwise torque won't run it!
  
jobexitstatus
  Reports a summary of the exit status for all jobs with output in
  ~/pbs-output/ or any other dir specified in the PBS_OUTPUT environment
  variable. Note that this requires that the exit status is included
  in the job output, e.g by using the torque.epilogue.sh script.
  
waitforjobs
  When submitting jobs with 'submitjob' it is possible to write the job
  ids to a file and pass this file to 'waitforjobs'. This script will
  then wait for these jobs to finish. It can be used as part of a shell
  script to allow for a batch of jobs to finish before doing a new
  submission. Note that it is also possible to submit jobs with dependencies
  on other jobs.
  
cache-qstat
  Admin script to wrap and add caching functionality to the default
  qstat command. Can be used to prevent clients from flooding the torque
  server with requests.
  
