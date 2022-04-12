# Trace Gas First Guesses

Author: Rebekah Esmaili (rebekah.esmaili@gmail.com)

NUCAPS uses a regression-based first guess for temperature, moisture, and ozone. For other trace gases, the first guess uses something akin to a climatology that is based on models and observations. Below documents the origin of select NUCAPS trace gas first guesses and the repository contains code to generate them. Note that this is a long term effort with contributions by many people, acklnowledgements are made where known.

## CO First Guess
The first guess is based on a monthly climatology of CO profiles from the Measurement of Pollution in the Troposphere (MOPITT; Drummon and Mand, 1996) instrument, which is on board the Terra satellite. To improve the first guess, NUCAPS performs a spatial and temporal interpolation to address the variation in profiles and seasonality of CO. Due to uniformity in the mean monthly average within hemisphere, if the field of regard is above 15&deg;N or below 15&deg;S, no spatial interpolation is performed and the profile is used “as is” for the Northern Hemisphere and Southern Hemisphere, respectively. In the tropics (15&deg;S-15&deg;N), to have a smooth transition, but the profiles are approximated by a linear interpolating the Northern and Southern profiles.

To address the seasonality of CO, the profiles are reported as monthly means. These profiles were developed by Juying Warner (UMD) and based on MOPITT CO profiles for [year]. As a result, the CO first guess profile consists of 12 monthly averages (to capture seasonality) and two hemispheres (to capture spatial variability), resulting in 24 distinct profiles in the first guess, which is imported into the retrieval. The retrieval then performs weights the profiles across time and space to calculate the first guess for a given latitude, longitude, and time.

Below is a code snippet (in pseudocode) to show how the profiles can be spatially interpolated by latitude when the FOR is between 15&deg;S and 15&deg;N. If the latitude is below 15&deg;S, then only the southern hemisphere (SH) profile is used, and vice versa. In between, there is 30 degrees of separation, so the distance of this latitude from 15&deg;N determined the weight. For instance, of the retrieval latitude is 7&deg;S, then northern hemisphere (NH) weight (WeightNH) is 0.27 and the southern hemisphere (WeightSH) is 0.73.

```
If (latituderetrieval < -15):
	WeightNH = 0.
If (latituderetrieval > 15):
	WeightNH = 1.
If (-15&deg;< latituderetrieval < 15):
	WeightNH = Abs (latituderetrieval + 15)/30
WeightSH = (1- WeightNH)
```

Since the CO climatologies are monthly averages of CO, the time is set to the middle of the month. So, the profile for month 1 (January) is given a date of Jan 15, and the next month (February) is February 15. If the retrieval is not exactly on their of these dates, the profile is weighted between the two. If the date is January 25, the weight value will be larger and the first guess will more closely resemble the January profile. To simplify this process, we recommend converting the calendar dates to fraction of year.

```
Timeclimatology (Month)= (Julian day of year) / (Number of days in year)
Weighttime = (Timeretrieval- TimeClimatology(Next Month)) /(TimeClimatology(Next Month) - TimeClimatology(Current Month))
```

In the snippet above, if the retrieval date is January 25, the date for the time of the climatology profile (TimeClimatology) for Current Month is January 15 and for Month2 it is February 15. These will respectively have Julian day 15 and 46. If it is a regular year with 365 days, the climatology time will be 0.041 and 0.126. The retrieval date, Jan 25 (Julian day 25), has a converted time of 0.068. The time weight (Weighttime) will then be (0.068 - 0.041)/( 0.126 - 0.041) =0.317.

Then, the difference in monthly climatology is calculated, and the weight will determine how much of the following month will be added (if the average CO concentration is higher) or subtracted (if it is lower).

```
dClimatology_month_SH = ClimatologyCO(Next Month, SH, Pressure) - ClimatologyCO(Current Month, SH, Pressure)
dClimatology_month_NH = ClimatologyCO(Next Month, NH, Pressure) - ClimatologyCO(Current Month, NH, Pressure)
```

Lastly, for each hemisphere, the weighted time average of the above climatology differences are added to the climatology for that month. The entire term is multiplied by the spatial weight for the hemisphere. The weighted northern and southern profiles are summed to get the first guess for CO, which is shown below.

```
ProfileCO,SH(Pressure) =
	WeightSH*(ClimatologyCO (Current Month, SH, Pressure) + weighttime*dClimatologymonth,SH)
Profile_CO_NH(Pressure) =
	WeightNH*( ClimatologyCO(Current Month, SH, Pressure) + weighttime*dClimatologymonth,NH)
ProfileCO(Pressure)  = Profile_CO_SH(Pressure) + Profile_CO_NH(Pressure)
```

## CH4 first guess

The CH4 first guess is a profile that was fitted to a latitudinal climatology of CH4 profiles from in-situ measurements (the primary source below 350 hPa) and model (the primary source above 350 hPA) data as of 2015. The fit is a non-linear function of latitude and altitude. The methane concentrations are higher in the Northern Latitudes and closer to the surface. The greatest variability in CH4 occurs in the middle troposphere, and the large drop off in CH4 is above the tropopause. There is no temporal variability in the first guess.

The method was originally developed by Xiaozhen Xiong on 3/12/2007. In situ observations are from NOAA/ESRL aircraft observation in 20 sites, and we used the averaged profile for each site weighed by its inverse of the standard deviation in regression. The ESRL observations are mostly in the northern hemisphere and the altitude is mostly below 350  mb, so monthly average of CH4 model data from Sander Houwelling is used to extrapolated the aircraft data to 100mb. Model data of zonal mean in 2004 is also used in regions of southern hemisphere and very high northern latitude where no real observations are available. Matseuda is also used but with little correction as it was observed several years ago. In the stratosphere, i.e. above 100mb, the average of the HALOE observation are used for five years, 2000-2005.

There are some limitations of this approach. Firstly, the first guess has no temporal dependence and thus does not account for increases in background methane (~1% each year). Second, from personal correspondence, the first guess is somewhat higher than JAMSTC model data. Improving the CH4 first guess is an area of ongoing work and research.

## References

* Maddy, E. S., C. D. Barnet, and A. Gambacorta, 2009: A Computationally Efficient Retrieval Algorithm for Hyperspectral Sounders Incorporating A Priori Information. IEEE Geoscience and Remote Sensing Letters, 6, 802–806, https://doi.org/10.1109/LGRS.2009.2025780.

* Drummond, J. R., and G. S. Mand, 1996: The Measurements of Pollution in the Troposphere (MOPITT) Instrument: Overall Performance and Calibration Requirements. J. Atmos. Oceanic Technol., 13, 314–320, https://doi.org/10.1175/1520-0426(1996)013<0314:TMOPIT>2.0.CO;2.

* NOAA/CMDL Methane Tracker. https://gml.noaa.gov/ccgg/carbontracker-ch4/

* NASA/Halogen Occultation Experiment (HALOE): https://www.nasa.gov/centers/langley/news/factsheets/Haloe.html
