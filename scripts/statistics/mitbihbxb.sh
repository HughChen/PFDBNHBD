#!/bin/bash
for f in *.qrs; do
	echo "Processing $f file.."
	name=${f%.qrs}
	echo "bxb -r $name -a ecg qrs -f 0 >$name.txt"
	bxb -r $name -a ecg qrs -f 0 >$name.txt
done

mkdir reportfiles
mv -v *.txt reportfiles
