#!/bin/bash

# Global Variables 
deleteintermediates=1
debug=0
nosmooth=0
nofloat=0
nobyte=0
maketif=0
noflip=0
file='trackcurrent-filename'
name='test'

# Modules


Stack-files-fix-header () # needs an input folder name (local path) and output file name
{
       	if [ $debug == 1 ]; then printf "dm2mrc $1/*3VBSED*.dm4 $2\n"; else dm2mrc $1/*3VBSED*.dm4 "$2"; fi

	raw_image_filename_array=($(ls $1/*3VBSED*.dm4))

# use an array to find the name of the first file, incase the first few have been deleted.
	
	position=$(strings -t d ${raw_image_filename_array[0]} | grep "Meta Data" | awk '{print $1+=162}') #Linux
	#position=$(strings -t d ${raw_image_filename_array[0]} | grep "Meta Data" | awk '{print $1+=161}') #test version for macbook
	printf "\n\n..........remember this is a test version............\n\n"
	#
	#This part doesn't work at the moment.  
	#For some reason the mac version gives a number 1 more than linux, so address is out by 1...?
	#
	#
	#
	#
# strings reads all the text in the file.  
# grep finds "Meta Data" the awk picks out the number (file offset) and then 162 is added

	thickness=$(od -j $position -N 4 -f ${raw_image_filename_array[0]} | awk '{print $2}')   

# goes to the position in the file found before (162 places on from Meta Data) 
# and pulls out the floating point number for cut thickness

printf "\n\nError-test Don\'t worry about the results if they seem sensible \nposition $position thickness $thickness file tested ${raw_image_filename_array[0]}\n\n"
	
	declare -x X_size=0.001
        #declare -i angstrom_thickness
	angstrom_thickness=$(awk '{print $1*10}'<<< $thickness)

	#check if Pixel size, or Pixel spacing?		
	X_size=$(header $2 | grep "Pixel spacing" | awk '{print $4}') #read x pixel from mrc file (saves the ugly attack on the DM4)

	printf "Error test angstrom thickness = $angstrom_thickness X-size = $X_size\n\n"
	
        if [ $debug == 1 ]; then printf "alterheader -del   $X_size,$X_size,$angstrom_thickness $2\n"; else alterheader -del   $X_size,$X_size,$angstrom_thickness $2; fi

}

Smooth () #$1 input file $2 output file (from now on)
{
	if [ $debug == 1 ]; then printf "clip smooth -2d $1 $2\n"; else clip smooth -2d $1 $2; fi
	if [ $deleteintermediates == 1 ]; then rm $1; fi
}

Float ()
{
	if [ $debug == 1 ]; then printf "newstack -float 2 $1 $2\n"; else newstack -float 2 $1 $2; fi
	if [ $deleteintermediates == 1 ]; then rm $1; fi
}

Make-byte () # input  mrc file in mrc file out 
{
        Znum=$(header $1 | grep "sections" | awk '{print $9}')
	if [ $Znum -gt "20" ]
	then
		imagetocheck1=10
		imagetocheck2=20
	else		
		imagetocheck1=1
		imagetocheck2=$Znum
	fi

	if [ $debug == 1 ]; then printf "trimvol -sz $imagetocheck1,$imagetocheck2 $1 $2\n"; else trimvol -sz $imagetocheck1,$imagetocheck2 $1 $2;   fi # may need a way to get non sign bytes
	if [ $deleteintermediates == 1 ]; then rm $1; fi
}

Make-tif ()
{
	mkdir $2
	mrc2tif $1 $2/$3
}

FlipX ()
{
	if [ $debug == 1 ]; then printf "clip flipx $1 $2\n"; else clip flipx $1 $2; fi
	if [ $deleteintermediates == 1 ]; then rm $1; fi
}



Main-part () # input folderpath name (ie name of folder without the /ROI00 etc?
{

	
	Stack-files-fix-header $1 $2'_initial.mrc'
	file=$2'_initial.mrc'
	

	if [ $nosmooth == 0 ]
	then
	    Smooth $file $2'_smoothed.mrc'
	    file=$2'_smoothed.mrc'
	fi
	if [ $nofloat == 0 ]
	then
		Float $file $2'_floated.mrc'
		file=$2'_floated.mrc'
	fi
	if [ $nobyte == 0 ]
	then
	    Make-byte $file $2'_byte.mrc'
	    file=$2'_byte.mrc'
	fi
	if [ $maketif == 1 ]
	then
	    Make-tif $file $2'_tifs' $2
	fi
	if [ $noflip == 0 ]
	then
	    FlipX $file $2'_flipped.mrc'
	    file=$2'_flipped.mrc'
	else
	    echo "NOTE This MRC stack will need to be reversed if volumes are generated in order to maintain  handedness"
	fi
	#Rename final file
	mv $file $2'.rec'

    
}
	







if [ $debug == 1 ]; then clear; printf "Debug-output\n\n"; else clear; printf "Standard-output\n\n"; fi


if [ $# -eq 0 ]   #added a bit last minute, so not indented properly
        then
        echo 
        echo "   Script to convert folders of dm4 files into MRC files)"
        echo "   Need to add usage instructions! "
        echo "    "
        echo "    "
        echo "   "
        echo
        echo "   note that the foldernames should not have spaces in them"
		printf "   current options are:	\n\n-keepintermediates -nosmooth -nofloat -nobyte -maketif -noflipX\n\n"


        else

#############################################
#                                           #
#              Main part here               #
#                                           #
#############################################
        if [ ! -d 3view_MRC_converted_files ] 
        then
	    mkdir 3view_MRC_converted_files #create a working directory
        fi
	cd 3view_MRC_converted_files
	# Perhaps add a test to check if we've run this before?  Would need to be done after the case part (ie once we know the base of the filename
fi


while [ $# -gt 0 ]; do

      case "$1" in

    -debug)
	echo "Debugging: meant to print what it would do... doesn't quite work just now"
        debug=1
	shift
        ;;
    -keepintermediates)
	tput bold
	echo "keep intermediate files"
	tput sgr0
	deleteintermediates=0
	shift
	;;
    -nosmooth)
	tput bold
	echo  "no smoothing"
	tput sgr0
	nosmooth=1
	shift
	;;
    -nofloat)
	tput bold
	echo "no floating mean intensity"
	tput sgr0
	nofloat=1
	shift
	;;
    -nobyte)
	tput bold
	echo "leave as 16bit"
	tput sgr0
	nobyte=1
	shift
	;;
    -maketif)
        tput bold
	echo "make tifs"
	tput sgr0
	maketif=1
	shift
	;;
    -noflipX)
	tput bold
	echo "no flipping image, reverse instead?"
	tput sgr0
	noflip=1
	shift
	;;
    *) # No specific parameter, therefore assume this is the first folder to work on
	# Need to remove the trailing / else wont work..
	printf "options set (or assuming full run) start working on first data folder:$1\n\n"

	 
	name=${1%/} #removes any / in the 'name'
	if [ -d ../$name ] #check name corresponds to a directory
	then
		testarray=($(ls ../$name | grep ROI_ ))  #find the number of elements in the array (ie number of folders to test)
	    let "test_num=${#testarray[@]}" #find the number of elements in the array (ie number of folders to test)
		if [ "$test_num" -gt "0" ]  #if the array exists then some ROIs were found
		then #we're effectively testing the same thing twice.  Does ROI exist and how many ROI file/folders are there?

			test_dir=../$name/${testarray[0]} 

			if [ -d $test_dir ] #check its a folder, not a file called xxx_ROI_xxx
			then
				pos=0
				until [ $pos = $test_num ]   #loops through the array of ROI names
				do #the meat of the ROI work
					ROI=${testarray[$pos]}
					working_folder='../'$name'/'$ROI
					save_file_name=$name'_'$ROI
					Main-part $working_folder $save_file_name
					let pos++

					
				done
			else
			    echo "This ROI is not a folder.  currently this wont work. perhaps run through"
			fi
		else
		    
		    Main-part '../'$1 $1
		fi
	else
	    echo  "Folder does not exist please check initial command"
	fi
	
	shift
       	;;
      esac
done


