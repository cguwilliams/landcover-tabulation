# Script by Patrick B. Williams - 2015
# Input a raster and shapefile(s). Output a series of .csv files with tabulated data
# Use separate script to concatenate .csv files into one file
# Note: There are most certainly more sophisticated/elegant ways of doing this, but this is my
# trial and error result!
# To speed up the script (takes five days even with a very fast computer), split up the outer 
# for loop either by running concurrent R sessions (my solution) or by multithreading (for-each)

library(rgdal)  # for the function readOGR
library(raster) # for the function raster and other raster based functions
library(mosaic) # for perctable

# load filepaths
# Define filepath for shapefile that agggregates the data to be tabulated (can be counties, states, grids, etc...)
county.all.fp <- '~/Documents/berman/data/cb_2014_us_county_20m/' 
# Define filepath for raster contaning data to be aggregated
landcover06.fp <- '~/Documents/berman/data/nlcd_2006_landcover_2011_edition_2014_10_10/nlcd_2006_landcover_2011_edition_2014_10_10.img'

# Create landcover raster (this can be plotted with plot(coverraster.r))
coverraster.r <- raster(landcover06.fp)

# load county shapefile
setwd(county.all.fp)                                                    # Move to directory where shapefile is located
county.all.shp <- readOGR(".","cb_2014_us_county_20m")                  # Create shape file (this can be plotted with (county.all.shp))
# transform shapefile to match projection of landcover projection
county.all.shp <- spTransform(county.all.shp, coverraster.r@crs)        # Ensure that shapefile and raster have the same projection
# remove states and territories not in landcover map
# 02 = Alaska; 11 = D.C.; 15 = Hawaii ; 72 = Puerto Rico
states.rm <- c("02","11","15","72") 
county.all.shp <- county.all.shp[!as.character(county.all.shp$STATEFP)
                                 %in% states.rm, ]
# sort county data by statefip then countyfip. This step is good housekeeping
county.all.shp <- county.all.shp[order(county.all.shp$STATEFP,county.all.shp$COUNTYFP),]

# Manually create the header for output data. Each number (except 0) matches a cover type
# the '0' value does not match a cover type, but is put here for NaN's
header <- as.vector(c("0",                              
                      "11","12",
                      "21","22","23","24",
                      "31",
                      "41","42","43",
                      "51","52",
                      "71",
                      "81","82",
                      "90","95"))

# This will serve as the header for the output text file
types  <- as.vector(c("openwater","snowice",
                      "devopen","devlow","devmed","devhigh",
                      "barren",
                      "desidueous","evergreen","mixedforest",
                      "dwarfscrub","shrubland",
                      "grasslands_herbaceuous",
                      "haypasture","cultivated",
                      "woodywetlands","emergentherbwetlands"))

# Get state fips for contiguous 48 states
state_fips <- unique(county.all.shp$STATEFP)

# Iterate process through each state (or shape in shapefile)
for (i in 1:length(state_fips)){
  # pick ith state by fip
  this_fip <- as.character(state_fips[i])
  # get county shapes for ith state
  state.this.shp <- county.all.shp[as.character(county.all.shp$STATEFP) %in% this_fip, ]
  # get number of counties within ith state
  n_counties <- length(state.this.shp$COUNTYFP)
  
  # d is a variable that will later hold the state data, broken down by county
  d <- data.frame(countyname=numeric(length(header)))
  
  # create vector of tables to store percent landcover data for each county within state
  # This creates a list of tables that is n_counties long. Each list will contain the landcover values for a single county
  vectorOfTables.perc <- vector(mode = 'list', length = n_counties)
  # print status of loop
  print(paste("BEGINNING PROCESSING - state fip:",this_fip))
  
  # Iterate through each county in the state. The script will output one file per state
  # with one line of tabulated per county
  for (j in 1:n_counties){
    # pick jth county by fip
    this_county <- as.character(state.this.shp$COUNTYFP[j])
    # print status of loop
    print(paste("PROCESSING county",j,"of",n_counties,":",as.character(state.this.shp$NAME[j])))
    # get shape of jth county (this can be plotted with plot(county.this.shp))
    county.this.shp <- state.this.shp[as.character(state.this.shp$COUNTYFP) %in% this_county,]
    # crop
    print("cropping...")
    coverraster.crop <- crop(coverraster.r, extent(county.this.shp))
    # rasterize. This step is time consuming
    print("rasterizing...")
    coverraster.county.r <- rasterize(county.this.shp, coverraster.crop)
    # mask
    print("masking...")
    coverraster.county.r.mask <- mask(coverraster.crop, coverraster.county.r)
    # Legends get changed during processing, and so we chaneg them to match the raster map
    coverraster.county.r.mask@legend <- coverraster.r@legend
    coverraster.county.r.mask[coverraster.county.r.mask==NA,] <- 0 # Feel free to fix this as the error indicates
    # Plot the cropped, rasterized, and masked county map (mostly to see your progress). Not necessary if want more speed
    plot(coverraster.county.r.mask)
    
    # Begin process of tabulating percentage land cover
    print("creating cover tables...")
    raster.mat <- as.matrix(coverraster.county.r.mask)  # First convert masked raster data to matrix format
    # Perctable {mosaic} quickly tabulates all data within county matrix data. It's the real gem of this script
    # Vectorization is a-MAZING!
    vectorOfTables.perc[[j]] <- perctable(raster.mat)
  } # End loop over counties
  # Create name for saved vectorOfTables variable
  datafilename <- paste(this_fip,"tables.RData",sep="_")
  # Save workspace incase there is an error
  save(vectorOfTables.perc, file = datafilename)
  
  # Begin manipulation of tabulated data for output file
  # The output of this loop will be a data.frame that has one column for each county (plus one for cover type index),
  # and one row for each cover type
  for (k in 1:n_counties){
    a <- data.frame(vectorOfTables.perc[k])     # Convert tabulated data to data.frame for single county
    b <- a[match(header,a$raster.mat),]         # Some counties don't have all cover types. This line ensures that each county
                                                # has at least an NA placeholder for these cover types
    c <- b[2]                                   # Remove cover type index column (not needed)
    d <- cbind(d,c)                             # combine each county with the one that came before, and for the first county,
                                                # merge with 'd' created earlier in the script
  }
  
  d[is.na(d)] <- 0                              # Replace NA values with zeros
  d <- d[-1,]                                   # Remove top row of data which is just going to be a zero (for NA's in raster data)
  
  countynames <- as.character(state.this.shp$NAME)      # Get all countynames for this state
  colnames(d)[2:dim(d)[2]] <- countynames               # Replace header of 'd' with county names
  
  d.df <- as.data.frame(t(as.matrix(d[,-1])))           # covert d to matrix, then transpose, then convert back to data.frame
  d.df <- cbind(statefp=this_fip,d.df)                  # Attach column of state fip values 
  d.df <- cbind(countygeoid=state.this.shp$GEOID,d.df)  # Attach column of county geoid's. This provides a precise way to
                                                        # identify counties for later joining of additional data
  
  colnames(d.df)[3:length(names(d.df))] <- types        # Change header to cover types (instead of indices)
  
  # Save each state's data. These individual files (of which there should be 48)
  # will later be joined to create one long dataset
  
  # Create file name/destination
  filename <- paste("~/path/where/you/want/to/save/data",this_fip,".csv",sep="")
  
  # Keep track of process
  print(paste("writing datafile for state fip",this_fip))
  
  # Save file
  write.csv(d.df,filename,row.names=F)

} # End of loop over state



