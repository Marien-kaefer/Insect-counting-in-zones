/*
Macro to count insects in a field of view split into smaller regions of interest.

												- Written by Marie Held [mheldb@liverpool.ac.uk] August 2022
												  Liverpool CCI (https://cci.liverpool.ac.uk/)
________________________________________________________________________________________________________________________

BSD 2-Clause License

Copyright (c) [2022], [Marie Held {mheldb@liverpool.ac.uk}, Image Analyst Liverpool CCI (https://cci.liverpool.ac.uk/)]

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 

*/



//reset ROI Manager
if (roiManager("count") > 0){
	roiManager("reset");
}

//get title of file to be processed and it's location
originalTitle = getTitle(); 
originalTitleWithoutExtension = file_name_remove_extension(originalTitle);
directory = File.directory;

//duplicate, plit channels and keep blue component only
run("Duplicate...", " ");
selectWindow(originalTitle);
run("Split Channels");
selectWindow(originalTitle + " (green)"); 
close();
selectWindow(originalTitle + " (red)");
close();
selectWindow(originalTitle + " (blue)");
rename(originalTitle);

//rotate the image to align the compartment edges to the horizontal and vertical planes
run("Rotate... ", "angle=2.5 grid=1 interpolation=Bilinear");
run("Replace value", "pattern=0 replacement=255"); //the rotation results in some pixels being black - pixels that were not part of the image originally. Set these pixels to white instead as the insect pixels are dark and therefore black background pixels could interfere with thresholding. Setting them to white will result in them being identified as "background" during thresholding. 
//filter the image to remove items smaller than the insects and much bigger than the insects
run("Top Hat...", "radius=8 light");
//data smoothing to reduce noise, the median filter is edge preserving
run("Median...", "radius=2");

//classify pixels into objects (white) and background (black)
setAutoThreshold("Otsu");
setOption("BlackBackground", true);
run("Convert to Mask");
//split touching objects
run("Watershed");

//check if the zoneROIs.zip file exists in the same folder as the image currently being processed. If it is not there, trigger a request to choose the correct directory. 
if (File.exists(directory + File.separator + "zoneROIs.zip") == 0){
	zones_file_directory = getDir("Choose the directory of file ''zoneROIs.zip'' ");
}
else{
	zones_file_directory = directory;
}

//open Roi set that contains the 16 rectangles in which the insects are to be counted
roiManager("Open", zones_file_directory + File.separator + "zoneROIs.zip");
numberOfRectangles = roiManager("count"); 
//set measurements to be done, none in this case as a count is all that is required. 
run("Set Measurements...", "  redirect=None decimal=3");

//iterate through the 16 rectangles and count the objects in each
for (i = 0; i<numberOfRectangles; i++){
	roiManager("Select", i);
	run("Analyze Particles...", "size=20-500 summarize"); //use an object size filter to dismiss any objects that are too small or too big to be insects
}
Table.rename("Summary", originalTitleWithoutExtension + "-counts"); //rename suumary file with original file name

//rename mask window to be more descriptive
selectWindow(originalTitle); 
rename(originalTitleWithoutExtension + "-mask");

function file_name_remove_extension(originalTitle){
	dotIndex = lastIndexOf(originalTitle, "." ); 
	file_name_without_extension = substring(originalTitle, 0, dotIndex );
	//print( "Name without extension: " + file_name_without_extension );
	return file_name_without_extension;
}