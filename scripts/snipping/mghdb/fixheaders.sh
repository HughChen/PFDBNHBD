#!/bin/bash
for f in *.hea; do
	echo "Processing $f file.."
	truncated="$(tr '\n' ' ' < $f | cut -d' ' -f 1-4)"
	echo $truncated > tmp.txt

	tail -n +2 $f >> tmp.txt
	rm $f
	mv tmp.txt $f
done
