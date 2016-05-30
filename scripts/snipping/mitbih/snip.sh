for f in *.hea; do
	echo "Processing $f file.."
	record=${f%.hea}
	numsamples=$(head -n 1 $f | cut -d " " -f 4)
	echo "Num Samples is $numsamples"
	freq=$(sampfreq $record)
	echo "Freq is $freq"
	recordtime=$(($numsamples / $freq))
	echo "Record time is $recordtime"
	segmenttime=600
	echo "Segment time is $segmenttime"
	numsegments=$(($recordtime / $segmenttime))
	echo "Num segments is $numsegments"
	for ((i=0;i<=numsegments;i++)); do
	    echo $i
	    newrecord=$record
	    newrecord+="A"
	    newrecord+=$i
	    start=$((i*600))
	    end=$(((i+1)*600))
	    if [ $start -ge $recordtime ];
		then
			echo "Done snipping"
		else
		    if [ $end -ge $recordtime ];
		    then
		    	echo "Last snip, end time is $end, record time is $recordtime"
		    	if [ $end -ne $recordtime ];
		    	then
		    		newrecord+="E"
		    		# Makes sure records at the end with a little bit left are distinguished
		    	fi
			fi

		    echo snip -i $record -n $newrecord -f $start -t $end -a ecg
		    snip -i $record -n $newrecord -f $start -t $end -a ecg
		fi
	done
done
