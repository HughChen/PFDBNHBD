These scripts were used to snip the longer records of the MIT-BIH Polysomnographic Database and the MGH/MF Waveform Database into 10 minute segments. We evaluated the performance of our algorithm against other PhysioNet 2014 Challenge submissions on these 2 datasets.

These scripts were tested and used on Mac OSX 10.9. They have not been tested on Linux or other Mac OSX versions.

# Prerequisites

Install the [WFDB Software Package](https://www.physionet.org/physiotools/wfdb.shtml).

Download the records for the [MIT-BIH Polysomnographic Database](https://www.physionet.org/physiobank/database/slpdb/) and [MGH/MF Waveform Database](https://www.physionet.org/physiobank/database/mghdb/).
  - Helpful [link](https://www.physionet.org/faq.shtml#downloading-databases) for downloading the entire databases at once.

# Using These Scripts

## MIT-BIH

* Copy snip.sh into the directory that the records for MIT-BIH are stored in. Make sure to copy [this file](https://github.com/HughChen/PFDBNHBD/blob/master/scripts/snipping/mitbih/snip.sh) and not the one for MGH/MF.
* Run snip.sh from the Terminal in the directory where the MIT-BIH records are.

```
cd "DirectoryWithMITBIHRecords"
chmod +x snip.sh
./snip.sh
```
This scripts snips the records, creates a new directory named snippedrecords, and moves all the newly created segments into that directory.

* Copy [fixheaders.sh](https://github.com/HughChen/PFDBNHBD/blob/master/scripts/snipping/mitbih/fixheaders.sh) into the newly created snippedrecords directory, and run fixheaders.sh from the Terminal in the directory where the snipped records are.

```
cd "DirectoryWithMITBIHRecords/snippedrecords"
chmod +x fixheaders.sh
./fixheaders.sh
```

If done properly, there should be 515 new records, for a total of 515 * 3 = 1545 files in the newly created snippedrecords directory.

## MGH/MF

* Copy snip.sh into the directory that the records for MGH/MF are stored in. Make sure to copy [this file](https://github.com/HughChen/PFDBNHBD/blob/master/scripts/snipping/mghdb/snip.sh) and not the one for MIT-BIH.
* Run snip.sh from the Terminal in the directory where the MGH/MF records are.

```
cd "DirectoryWithMGHMFRecords"
chmod +x snip.sh
./snip.sh
```
This scripts snips the records, creates a new directory named snippedrecords, and moves all the newly created segments into that directory.

* Copy [fixheaders.sh](https://github.com/HughChen/PFDBNHBD/blob/master/scripts/snipping/mghdb/fixheaders.sh) into the newly created snippedrecords directory, and run fixheaders.sh from the Terminal in the directory where the snipped records are.

```
cd "DirectoryWithMGHMFRecords/snippedrecords"
chmod +x fixheaders.sh
./fixheaders.sh
```

* Copy [lessthan20beats.txt](https://github.com/HughChen/PFDBNHBD/blob/master/scripts/snipping/mghdb/lessthan20beats.txt) into the snippedrecords directory. Then, run the following command 

```
xargs rm < lessthan20beats.txt
```

This command removes any records that had less than 20 recorded heart beats.

* Open mgh067A0.hea, mgh067A1.hea, mgh067A2.hea, mgh067A3.hea, mgh067A4.hea, and mgh067A5.hea, and lowercase the word "Signal" in the phrase "(Signal is still clipped on CH8)".

If done properly, there should be 1576 new records, for a total of 1576 * 3 = 4728 files in the newly created snippedrecords directory.

# Miscellaneous Notes
* fixheaders.sh deletes date and time information in the header. This step is required to make these records compatible with the [WFDB Toolbox for MATLAB and Octave](https://physionet.org/physiotools/matlab/wfdb-app-matlab/), which we use extensively in the implementation of our algorithm.
* "Signal" needs to be lower cased in the headers for mgh067 because of how the WFDB Toolbox parses headers.
* mgh127 will not end up as part of the snipped records because the header indicates that it has a length of 0 seconds. We did not include it in the dataset when evaluating our algorithm.
* We found records with less than 20 beats by examining the bxb report files across the dataset, and using a script that examined the report files to locate such records.
