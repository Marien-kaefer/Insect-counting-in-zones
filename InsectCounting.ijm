if (roiManager("count") > 0){
	roiManager("reset");
}

originalTitle = getTitle(); 
originalTitleWithoutExtension = file_name_remove_extension(originalTitle);
directory = File.directory;

run("Duplicate...", " ");
selectWindow(originalTitle);
run("Split Channels");
selectWindow(originalTitle + " (green)"); 
close();
selectWindow(originalTitle + " (red)");
close();
selectWindow(originalTitle + " (blue)");
rename(originalTitle);

run("Rotate... ", "angle=2.5 grid=1 interpolation=Bilinear");
run("Replace value", "pattern=0 replacement=255");
run("Top Hat...", "radius=8 light");
run("Median...", "radius=2");

setAutoThreshold("Otsu");
setOption("BlackBackground", true);
run("Convert to Mask");
run("Watershed");

if (File.exists(directory + File.separator + "zoneROIs.zip") == 0){
	zones_file_directory = getDir("Choose the directory of file ''zoneROIs.zip'' ");
}
else{
	zones_file_directory = directory;
}

roiManager("Open", zones_file_directory + File.separator + "zoneROIs.zip");
numberOfRectangles = roiManager("count");
//selectWindow(preprocessedImage);
run("Set Measurements...", "  redirect=None decimal=3");

for (i = 0; i<numberOfRectangles; i++){
	roiManager("Select", i);
	run("Analyze Particles...", "size=20-500 summarize");
}
Table.rename("Summary", originalTitleWithoutExtension + "-counts");

selectWindow(originalTitle); 
rename(originalTitleWithoutExtension + "-mask");

function file_name_remove_extension(originalTitle){
	dotIndex = lastIndexOf(originalTitle, "." ); 
	file_name_without_extension = substring(originalTitle, 0, dotIndex );
	//print( "Name without extension: " + file_name_without_extension );
	return file_name_without_extension;
}