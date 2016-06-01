#!/bin/bash

for f in *.dat; do
	echo "Processing $f file.."
	name=${f%.dat}
	sh ./next.sh $name
done

mkdir annotations
mv -v *.qrs annotations
