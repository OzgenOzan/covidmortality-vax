# covidmortality-vax

We are examining the correlation between covid-19 mortality and vaccination. Our data set consists information of 'new cases', 'new deaths', '% of Vaccination' sorted by date, for various countries ('% of Vaccination' is according the ratio of Total Doses Administered/Total Population). Our goal is to present effectiveness of vaccines (on the death ratio) with graphics which can be understand by general public.

The data set which was used gathered from Our World in Data's covid-19-data repository(^1).

We are using R Studio, version 1.4.1717, along with R for Windows, version 4.1.0, with these packages; pacman, readxl, tseries in addition to system library packages.

We have manipulated the data set with; lag of 7, 9 and 12 days on 'new cases' because the 'new deaths' follows the 'new cases' with a delay (the length of this 'delay' also variates with new variants and rate of vaccination) and converted our data to time series.

We have used Simple Moving Average (SMA) for smoothing since our data is noisy because there are lots of data missing for various dates (throughout the pandemic data flow from institutions have been intermittent).

(^1) https://github.com/owid/covid-19-data

```

library (pacman)

p_load (readxl, tseries)

uk <- read.csv("C:/Users/'username'/Desktop/'filename'.csv", header = T)
'filename'[is.na('filename')] = 0

'filenamecases' <- 'filename' %>%
  select("date", "ncases")

class('filenamecases')
'filenamecases'$date <- as.Date('filenamecases')
head('filenamecases')

lag0 <- lag('filenamecases', n=5)

lag1 <- lag('filenamecases', n=7)

lag2 <- lag('filenamecases', n=9)

'filename_ts1' <- ts(lag1[, 2], start = c(1, 1), end = c(515, 1), frequency = 1)

'filename_ts1'

'filenamedeaths' <- 'filename' %>%
  select("date", "ndeaths")

'filename_ts2' <- ts('filenamedeaths'[, 2], start = c(1, 1), end = c(515, 1), frequency = 1)      

'filename_ts1' <- pmax('filename_ts1',0)

c1 = range('filename_ts1', na.rm=T)

c1

c2 = range('filename_ts2', na.rm=T)

c2

plot('filename_ts1', ylim=c1, ylab="Cases")

par(new=T)

plot('filename_ts2', ylab=NA, axes=F, col="red", ylim=c(0, 2000))

axis(4, las=0, ylab="Deaths", tck=0.01)

mtext("Deaths", side=4, col="red")

par(new=T)

plot('filename$tvaxp', ylab=NA, axes=F, col="green", ylim=c(0, 100))

mtext("% Vaccination", side=3, col="green")

```

