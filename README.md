# covidmortality-vax

We are examining the correlation between covid-19 mortality and vaccination. Our data set consists information of 'new cases', 'new deaths', '% of Vaccination' sorted by date, for various countries ('% of Vaccination' is according the ratio of Total Doses Administered/Total Population). Our goal is to present effectiveness of vaccines (on the death ratio) with graphics which can be understand by general public.

The data set which was used gathered from Our World in Data's covid-19-data repository[^1].

We are using R Studio, version 1.4.1717, along with R for Windows, version 4.1.0, with these packages; pacman, readxl, tseries in addition to system library packages.

We have manipulated the data set with; lag of 7, 9 and 12 days on 'new cases' because the 'new deaths' follows the 'new cases' with a delay (the length of this 'delay' also variates with new variants and rate of vaccination) and converted our data to time series.

We have used Simple Moving Average (SMA) for smoothing since our data is noisy because there are lots of data missing for various dates (throughout the pandemic data flow from institutions have been intermittent).

[^1]: https://github.com/owid/covid-19-data

```

# Pacman, version 0.4.1 is used to organize the packages used in R.

library (pacman)

p_load (readxl, tseries)

# If you are using additional packages, or feel like it, you can use `conflict_scout()` command from *conflicted* package to check conflicts betweeen packages.

# I've seperated countries before importing to R. After importing the .csv file, we are filling N/A data with 0s.

> uk <- read.csv("C:/Users/'username'/Desktop/'filename'.csv", header = T)

> 'filename'[is.na('filename')] = 0

> 'filenamecases' <- 'filename' %>%
    select("date", "ncases")
    
# To prevent errors, we are converting the date column as dates.

'filenamecases'$date <- as.Date('filenamecases')

head('filenamecases')

# Since we have mentioned new deaths follows new cases with a lag, for various reasons, and the time gap changes. So we are using different lag.

> lag0 <- lag('filenamecases', n=7)

> lag1 <- lag('filenamecases', n=9)

> lag2 <- lag('filenamecases', n=12)

# Converting these to time series (only converted one for this example)

> 'filename_ts1' <- ts(lag1[, 2], start = c(1, 1), end = c(515, 1), frequency = 1)

> 'filename_ts1'

# For comparison to deaths, we are extracting the new deaths data, and converting it to time series as well.

> 'filenamedeaths' <- 'filename' %>%
    select("date", "ndeaths")

> 'filename_ts2' <- ts('filenamedeaths'[, 2], start = c(1, 1), end = c(515, 1), frequency = 1)      

> 'filename_ts2'

# Since we used lag on new cases data, the length of it (as a vector) changed, but for comparison we need the original length.

> 'filename_ts1' <- pmax('filename_ts1', 0)

# When comparing the numbers, we need them to be scaled, so we can see clearer on plotted graphic/chart

> c1 = range('filename_ts1', na.rm=T)

> c1

> c2 = range('filename_ts2', na.rm=T)

> c2

# We are starting to plot, and want 3 different variables to be presented together.

>plot('filename_ts1', ylim=c1, ylab="Cases")

> par(new=T)

> plot('filename_ts2', ylab=NA, axes=F, col="red", ylim=c(0, 2000))

> axis(4, las=0, ylab="Deaths", tck=0.01)

> mtext("Deaths", side=4, col="red")

> par(new=T)

> plot('filename$tvaxp', ylab=NA, axes=F, col="green", ylim=c(0, 100))

> mtext("% Vaccination", side=3, col="green", ylim=c(0, 100))

# Thank you for your interest.

```

