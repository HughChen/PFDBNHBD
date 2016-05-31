# PFDBNHBD

## Running the Particle Filter

1. Clone the repo.
2. Open MATLAB script particle_filter/particle_filter.m.
3. Modify lines 10-11 to set <code>record_name</code> as the path to your file.
4. Run the script.  Currently, it'll print out the sensitivity and positive predictivity for the PF, GQRS, and WABP.

## Misc. Notes

* The scripts that were used to prepare the MIT-BIH and MGH/MF databases and to generate statistics can be found in the scripts/ directory.
* The repo comes with setp1 and setp2 available at the Physionet 2014 challenge <a href="https://www.physionet.org/challenge/2014/">website</a>. 
* We assume that the signals come in a form compatible with the <a href="https://physionet.org/physiotools/matlab/wfdb-app-matlab/">WFDB toolbox</a> (we've included the toolbox in this repo).  
* We'll be updating the functions/scripts over time to improve documentation.
* We've provided the utility script that we used to generate our graphs.

## Questions/Contact

If you have any questions, feel free to send an email to hugh.chen1{at}gmail.com.