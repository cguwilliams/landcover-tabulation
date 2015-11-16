# script to merge data from each state for land cover - 09/09/15: copied and modified from original
# Patrick B. Williams
# This script could be pasted to the end of 'covertabulation.R' if you're careful

# Filepath where cover type files are
fp <- '~/source/of/individual/text/files'
# Collect filepaths of all files in directory 'fp'
filenames <- Sys.glob(file.path(fp,'*.csv'))

# Create a data.frame to contain all data. Each file will be loaded and stuck to the
# end (concatenated) of this structure
df <- data.frame()

# for each file in the list of filenames... do this!
for(file in filenames) {
  # read ith data file
  temp <- read.csv(file, header = T, nrows = -1)
  # bind info from ith data file to existing data
  df   <- rbind(df,temp)
}

# Round data (optional) and doesn't seem to work in Ubuntu
df.round <- round(df[4:length(df)], digits=3)

df[4:length(df)] <- df.round

# Write final datafile. IN the county data example, the file is 14 or so columnes by approximately 3000 lines long
# One row per cover type (plus columns to identify states/counties) and one row per county
write.csv(df,'~/Documents/berman/allstate_cover_06.csv')