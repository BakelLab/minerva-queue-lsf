#!/bin/bash

# Copy the perl scripts from the github repo to the PREFIX/bin folder
mkdir -p $PREFIX/bin/
cp bin/* $PREFIX/bin/
chmod u+x $PREFIX/bin/*
