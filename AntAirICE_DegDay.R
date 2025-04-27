# Load required libraries
library(raster)
library(terra)
library(stringr)
library(dplyr)
library(lubridate)

# ------------------------- USER SETTINGS -------------------------

# Define input and output paths
input_path <- "//file.canterbury.ac.nz/Research/AntarcticaFoehnWarming/AntAir v.2/Final"    # <-- Update if needed
output_path <- "//file.canterbury.ac.nz/Research/AntarcticaFoehnWarming/AntAir v.2/N/"       # <-- Update if needed

# Set years to process
years <- 2013:2021

# Create output folder if it doesn't exist
if (!dir.exists(output_path)) {
  dir.create(output_path, recursive = TRUE)
}

# ------------------------- PROCESS EACH YEAR -------------------------

# Store outputs to later sum them if needed
degday_rasters <- list()

for (i in 1:length(years)) {
  
  # ----- JAN-FEB (current year) -----
  days_jan_feb <- str_pad(1:59, width = 3, pad = "0")
  dates_jan_feb <- str_c(years[i], "_", days_jan_feb)
  
  files_jan_feb <- list.files(
    path = input_path, 
    pattern = paste0("AntAir_ICE_", dates_jan_feb, collapse = "|"), 
    full.names = TRUE
  )
  
  rasters_jan_feb <- brick(lapply(files_jan_feb, raster, band = 1))
  
  # Mask non-positive temperatures
  rasters_jan_feb[rasters_jan_feb <= 0] <- NA
  rasters_jan_feb[rasters_jan_feb > 0] <- 1
  
  sum_jan_feb <- calc(rasters_jan_feb, sum, na.rm = TRUE)
  
  # ----- NOV-DEC (next year) -----
  if (i < length(years)) {  # Avoid overflow at last year
    days_nov_dec <- str_pad(305:366, width = 3, pad = "0")
    dates_nov_dec <- str_c(years[i + 1], "_", days_nov_dec)
    
    files_nov_dec <- list.files(
      path = input_path, 
      pattern = paste0("AntAir_ICE_", dates_nov_dec, collapse = "|"), 
      full.names = TRUE
    )
    
    rasters_nov_dec <- brick(lapply(files_nov_dec, raster, band = 1))
    
    rasters_nov_dec[rasters_nov_dec <= 0] <- NA
    rasters_nov_dec[rasters_nov_dec > 0] <- 1
    
    sum_nov_dec <- calc(rasters_nov_dec, sum, na.rm = TRUE)
    
    # ----- TOTAL FOR EXTENDED SUMMER -----
    degday_sum <- sum_jan_feb + sum_nov_dec
  } else {
    # If last year, only use Jan-Feb
    degday_sum <- sum_jan_feb
  }
  
  # Save each year's degree days raster
  output_filename <- file.path(output_path, paste0("Sum_DegDay_", years[i], "_", years[i+1], ".tif"))
  
  writeRaster(degday_sum, output_filename, format = "GTiff", options = c("COMPRESS=NONE"), overwrite = TRUE)
  
  # Save the raster to a list for final summation
  degday_rasters[[i]] <- degday_sum
  
  cat("Saved:", output_filename, "\n")
}

# ------------------------- SUM ALL YEARS TOGETHER -------------------------

# Stack all rasters and calculate total sum
final_degday_sum <- Reduce("+", degday_rasters)

# Save final summed raster
final_output_file <- file.path(output_path, "Sum_DegDay_Total_2013_2021.tif")

writeRaster(final_degday_sum, final_output_file, format = "GTiff", options = c("COMPRESS=NONE"), overwrite = TRUE)

cat("Saved total degree days file:", final_output_file, "\n")
