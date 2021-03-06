#!/bin/bash -l
# Script that converts raw OISST AVHRR daily files to final yearly files
# step1: unzip files in temporary directory
# step2: use cdo to concatenate 1 year files along time dimension, while saving output file as compressed netcdf4  
# step3: use nco to make yearly files CF1.6 compliant  
# Take year as input
# Author Paola Petrelli paolap@utas.edu.au
# Last update:
#        2017-01-04
#        2017-03-03 - fixed problem with cdo command: "tmp/*${year}*.nc was concatenating files from other years
#                     "tmp/*-v2.${year}*.nc" is more restrictive
#                    - added code in step1 to account for exception: files that already uncompressed on the ftp server
#                    - introduced new step2 to handle preliminary files
#                    - improved script syntax 

# Loading modules cdo and nco
module load cdo/1.7.1
# use -L flag with cdo when working with netCDF4 serialised I/O because of CDO non-thread-safe bug when chaining commands 
module load nco/4.5.3

year=$1
today=`date +%Y-%m-%d`
tmpdir="/g/data1/ua8/Convert/OISST/tmp"
rawdir="/g/data1/ua8/NOAA_OISST/AVHRR/raw"
cd /g/data1/ua8/Convert/OISST/

# step1: unzip files in temporary directory
for f in ${rawdir}/${year}/avhrr-only-v2.${year}*[0-9].nc.gz; do
    echo $f
    outf=$(basename ${f} .gz)
    gunzip -c $f > ${tmpdir}/${outf}
done
# this is to take into account exception in which the uploaded file is not compressed
for f in ${rawdir}/${year}/*.nc; do
    outf=$(basename ${f} .nc)
    cp ${f} ${tmpdir}/${outf}
done

# step2: check if there are preliminary files and if they should be included or deleted 
for f in ${rawdir}/${year}/*preliminary*.nc.gz; do
    echo $f
    outf={basename ${f} .gz}
    notprelim=${outf/_preliminary/}
    if [ -e ${tmpdir}/${notprelim} ]; then
       echo $f 
# eventually rm
    else
       gunzip -c $f > ${tmpdir}/${outf}
    fi
done

# step3: use cdo to concatenate 1 year files along time dimension, while saving output file as compressed netcdf4  

cdo -L --no_history -f nc4 -z zip_5 mergetime tmp/*-v2.${year}*.nc /g/data1/ua8/NOAA_OISST/AVHRR/v2-0_modified/oisst_avhrr_v2_${year}.nc

# step3: use nco to make yearly files CF1.6 compliant  
cd /g/data1/ua8/NOAA_OISST/AVHRR/v2-0_modified
ncatted -h -a standard_name,sst,o,c,"sea_surface_temperature" oisst_avhrr_v2_${year}.nc
#ncatted -h -a standard_name,anom,o,c,"sea_surface_temperature_anomaly" oisst_avhrr_v2_${year}.nc
ncatted -h -a standard_name,ice,o,c,"sea_ice_area_fraction" oisst_avhrr_v2_${year}.nc
# add/fix global attributes
ncatted -h -O -a summary,global,c,c,"Original files downloaded from ftp://eclipse.ncdc.noaa.gov/pub/OI-daily-v2/NetCDF/${year}/AVHRR/\n and concatenate in 1 yearly file using: cdo -f nc4 -z zip_5 mergetime <infiles> outfile.\n Original attributes modified using NCO" oisst_avhrr_v2_${year}.nc
ncatted -h -O -a Conventions,global,o,c,"CF-1.6" oisst_avhrr_v2_${year}.nc 
ncatted -h -O -a date_created,global,c,c,${today} oisst_avhrr_v2_${year}.nc
ncatted -h -a time_coverage_start,global,c,c,"${year}-01-01" oisst_avhrr_v2_${year}.nc
ncatted -h -a time_coverage_end,global,c,c,"${year}-12-31" oisst_avhrr_v2_${year}.nc
ncatted -h -a geospatial_lat_min,global,c,d,-89.875 oisst_avhrr_v2_${year}.nc
ncatted -h -a geospatial_lat_max,global,c,d,89.875 oisst_avhrr_v2_${year}.nc
ncatted -h -a geospatial_lon_min,global,c,d,0.125 oisst_avhrr_v2_${year}.nc
ncatted -h -a geospatial_lon_max,global,c,d,359.875 oisst_avhrr_v2_${year}.nc
#ncatted -h -a publisher_name,global,o,c,"ARCCSS data manager" oisst_avhrr_v2_${year}.nc
#ncatted -h -O -a publisher_email,global,o,c,"paola.petrelli@utas.edu.au" oisst_avhrr_v2_${year}.nc

 
