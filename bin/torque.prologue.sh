#!/bin/sh

# 02.10.2012 10:16:16 EDT
# Harm van Bakel <hvbakel@gmail.com>

# Copy this script to $HOME/.torque.prologue to have submitjob use it in a job 
# submission automatically. Note that the script must be chmod 700, otherwise
# torque won't run it.

# Create job-specific /dev/shm temporary folder
mkdir -p -m 700 /dev/shm/$1
exit 0;
