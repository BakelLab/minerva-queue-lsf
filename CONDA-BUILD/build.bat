#!/bin/bash

# Copy the perl scripts from the github repo to the PREFIX/bin folder
mkdir %PREFIX%\bin\
copy bin\* %PREFIX%\bin\
IF %ERRORLEVEL% NEQ 0 exit /B 1
