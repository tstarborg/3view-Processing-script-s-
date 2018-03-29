# 3view processing script#

This is a bash script that is meant to process 3view data stacks and generate an MRC stack

To use 

new-3view-dm4-script.sh OPTIONS folder outputname
Options are:
-keepintermediates -nosmooth -nofloat -nobyte -maketif -noflipX
I think that each of these has to be written out in full.  

As standard the script does the following
stacks raw dm4 files
smooths the data (gausian smoothing with a 3x3 kernal)
floats the data to the same mean/standard deviation
flips the data about the x axis.
converts the data to byte.

Running with no options is useful for manual tracing with relatively homogenous staining, but wont work well if the stain
density changes, or if you want to do some computational procssing.

The options have the following effects:
keepintermediates: keeps all the files as it goes along in case there is an issue with a particular step
nosmooth: does not smooth the data, which is useful if you need to process with other software.
nofloat: leaves the data with standard pixel values, which is useful if there are large changes in intensity 
(eg variable ammounts of empty resin)
nobyte: keeps data 16bit.   
maketif: makes a folder and fills this with tifs 1 per slice 
noflipX:  Does not flip teh data about the x axis.  Flipping the data is necessary as 3view slices are numbered from the top
down, while MRC stacks are numbered from the bottom up.  Another option would be to reverse the slice order.  If this effect
is not corrected then models with a twist will have the wrong handedness.
