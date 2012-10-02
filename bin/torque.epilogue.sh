#!/bin/sh

# 25.05.2012 14:11:34 EDT
# Harm van Bakel <hvbakel@gmail.com>

# Copy this script to $HOME/.torque.epilogue to have submitjob use it in a job 
# submission automatically. Note that the script must be chmod 700, otherwise
# torque won't run it.

# include job resource usage and exit status info
declare -A ex=( ["0"]="(Job exited normally)" \
                ["-1"]="(job exec failed, before files, no retry)" \
                ["-2"]="(job exec failed, after files, no retry)" \
                ["-3"]="(job execution failed, do retry)" \
                ["-4"]="(job aborted on MOM initialization)" \
                ["-5"]="(job aborted on MOM init, chkpt, no migrate)" \
                ["-6"]="(job aborted on MOM init, chkpt, ok migrate)" \
                ["-7"]="(job restart failed)" \
                ["-8"]="(exec() of user command failed)" \
                ["1"]="(general error, check job output file)" \
                ["2"]="(misuse of shell builtins)" \
                ["126"]="(command invoked cannot execute)" \
                ["127"]="(command not found)" \
                ["128"]="(invalid argument to 'exit')" \
                ["130"]="(script terminated by Ctrl+C)" \
                ["139"]="(Segmentation fault)" \
                ["271"]="(job terminated by user or by queuing system for exceeding resources)" )

echo "==> Resources used : ${7}"
echo "==> Exit status    : ${10}" ${ex["${10}"]}

# Remove job-specific /dev/shm temporary folder
rm -rf /dev/shm/$1
exit 0;
