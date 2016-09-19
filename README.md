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
* We utilized some of the SQI functions from Alistair Johnson's entry.  The original source can be found <a href="http://physionet.org/challenge/2014/sources/">here</a>.  Their paper detailing their work can be found <a href="http://iopscience.iop.org/article/10.1088/0967-3334/36/8/1665">here</a>.
* We'll be updating the functions/scripts over time to improve documentation.
* We've provided the utility script that we used to generate our graphs.

## Paper

**Probabilistic model-based approach for heart beat detection**
Hugh Chen, Yusuf Erol, Eric Shen and Stuart Russell
Published August 2nd 2016 in Physiological Measurement, Volume 37, Number 9
<a href="http://iopscience.iop.org/article/10.1088/0967-3334/37/9/1404">PDF</a>

## Questions/Contact

If you have any questions, feel free to send an email to hugh.chen1{at}gmail.com and ericshen{at}berkeley.edu.
