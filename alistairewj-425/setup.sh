#! /bin/bash

# file: setup.sh

# This bash script performs any setup necessary in order to test your entry.
# It is run only once, before running any other code belonging to your entry.

# Install the WFDB Toolbox for MATLAB and Octave
unzip sources/wfdb-app-toolbox-*.zip

# Configure the toolbox to use the custom native library built on Debian Wheezy
sed -i 's/WFDB_CUSTOMLIB=0;/WFDB_CUSTOMLIB=1;/' ./mcode/wfdbloadlib.m

OCTAVE='octave --quiet --eval '
STR="${OCTAVE} \"cd('mcode');addpath(pwd);savepath;quit;\""
echo "$STR"
eval ${STR}
stty sane

OCTAVE='octave --quiet --eval '
STR="${OCTAVE} \"cd('sources');addpath(pwd);savepath;quit;\""
echo "$STR"
eval ${STR}
stty sane

# compile epltd

gcc -I/usr/local/include -c epltd_challenge.c
gcc -c bdac.c
gcc -I/usr/local/include -c classify.c
gcc -I/usr/local/include -c rythmchk.c
gcc -c noisechk.c
gcc -I/usr/local/include -c match.c
gcc -I/usr/local/include -c postclas.c
gcc -c analbeat.c
gcc -c qrsfilt.c
gcc -c qrsdet.c
gcc -g -O -DWFDB_MAJOR=10 -DWFDB_MINOR=5 -DWFDB_RELEASE=23 -I/usr/local/include -Wl,--no-as-needed,-rpath,/usr/local/lib64 -o epltd_challenge epltd_challenge.o bdac.o classify.o rythmchk.o noisechk.o match.o postclas.o analbeat.o qrsfilt.o qrsdet.o -lwfdb `curl-config --libs` -lm


