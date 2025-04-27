# Load required libraries
library(raster)
library(terra)
library(stringr)
library(dplyr)
library(lubridate)

# ------------------------- USER SETTINGS -------------------------

# Define input and output paths
input_path <- "path/to/your/AntAir_ICE_files"    # <-- Change this
output_path <- "path/to/save/annual_max"         # <-- Change this

# Set years to process
years <- 2003:2021

# Temporary directory for intermediate files
temp_dir <- tempdir()

# Create output folder if it doesn't exist
if (!dir.exists(output_path)) {
  dir.create(output_path, recursive = TRUE)
}

# ------------------------- CALCULATE ANNUAL MAXIMUM -------------------------

for (year in years) {
  
  # List all files for the current year
  year_files <- list.files(
    path = input_path, 
    pattern = paste0("AntAir_ICE_", year, "_"), 
    full.names = TRUE
  )
  
  # Load only the first band from each file
  stack_files <- rast(year_files, lyrs = seq(1, length(year_files) * 2, 2))
  
  # Calculate annual maximum
  annual_max <- app(stack_files, max, na.rm = TRUE)
  
  # Apply scaling factor
  annual_max <- annual_max * 0.1
  
  # Define output file name
  output_file <- file.path(output_path, paste0("AntAir_", year, "_Yr_max.tif"))
  
  # Save annual maximum raster
  writeRaster(annual_max, output_file, gdal = c("COMPRESS=NONE"), overwrite = TRUE)
  
  # Clean temporary files
  temp_files <- list.files(temp_dir, full.names = TRUE, pattern = "^file")
  file.remove(temp_files)
  
}

# ------------------------- CALCULATE OVERALL MAXIMUM -------------------------

# List all annual maximum files
annual_files <- list.files(
  path = output_path, 
  pattern = "AntAir_\\d{4}_Yr_max\\.tif$", 
  full.names = TRUE
)

# Load all annual maximum rasters
all_annual_rasters <- rast(annual_files)

# Calculate maximum across all years
overall_max <- app(all_annual_rasters, max, na.rm = TRUE)

# Define overall output file name
overall_output_file <- file.path(output_path, "AntAir_Yr_max.tif")

# Save overall maximum raster
writeRaster(overall_max, overall_output_file, gdal = c("COMPRESS=NONE"), overwrite = TRUE)

# Clean temporary files again
temp_files <- list.files(temp_dir, full.names = TRUE, pattern = "^file")
file.remove(temp_files)

