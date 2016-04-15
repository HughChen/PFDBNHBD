#! /bin/bash

# file: next.sh

# This bash script analyzes the record named in its command-line argument ($1),
# saving the results as an annotation file for the record, with annotator 'qrs'.
# This script is run once for each record in the Challenge test set.

# For example, if invoked as
#    next.sh 100
# it analyzes record 100 using 'gqrs', and saves the results as an annotation
# file named '100.qrs'.

OCTAVE='octave --quiet --eval '
RECORD=$1
RPATH=`pwd`

# duplicate the first 5 sec of the record
FS=`cat $RECORD.hea | head -n 1 | awk '{print $3}'`
rdsamp -r ${RECORD} -f 0 -t 5 > tmp1
tac tmp1 > tmp
rdsamp -r ${RECORD} >> tmp
cat tmp | wrsamp -o ${RECORD}ep -F $FS -z

# rename signals
N=`wc -l ${RECORD}.hea | awk '{print $1}'`
for ((n=1; n < N ; n++))
do
	OLDLEAD=`cat ${RECORD}.hea | head -n $((n+1)) | tail -n 1 | cut -d" " -f9-`
	sed -i "$((n+1))s/col $n/${OLDLEAD}/" ${RECORD}ep.hea
done

# run epltd
./epltd_challenge -r ${RECORD}ep
# we will later need to subtract 5s from the annot

# This calls the c-code through octave
STR="${OCTAVE} \"challenge('$RECORD'); quit;\" 2>&1"

echo "$STR"
eval ${STR}
