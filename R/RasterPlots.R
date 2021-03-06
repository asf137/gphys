#' Make a raster plot from a set of Nclamp sweeps recording odour responses
#' 
#' @details Note that can also give a spiketimes list from 
#'   CollectSpikesFromSweeps By default the odour stimulus is represented by a 
#'   pale red rectangle in a layer behind the spikes. If pch takes the special 
#'   value "rect" then rectangles of width dotwidth are drawn. spikewidth will 
#'   then specify the relative size of the spikes with 1 resulting in the top of
#'   spikes from one line at the same height as the base of spikes in the line 
#'   above. If more than one stimulus is required, odourRange can be specified 
#'   as a vector of successive start,stop times e.g. 
#'   c(start1,stop1,start2,stop2).
#' @inheritParams CollectSpikesFromSweeps
#' @param xlim x axis range of plot
#' @param main main title of plot (see \code{\link{title}})
#' @param sub subtitle of plot
#' @param xlab axis label (default Time/ms)
#' @param ylab axis label (default odour)
#' @param xaxis (default TRUE)
#' @param yaxis (default TRUE)
#' @param frame.plot Plot a box around the whole plot (default TRUE)
#' @param xaxs,yaxs Whether to extend xlim,ylim by 4 percent (see ?par, default FALSE)
#' @param pch plotting character (default 22 is a square, see details for rect)
#' @param dotcolour colour of dots in raster plot (default black)
#' @param dotsize size of dots in raster plot (default 0.5)
#' @param dotwidth Width in ms of rectangle when pch='rect'
#' @param spikeheight Relative height of spike when pch='rect' (default 0.8)
#' @param odourRange time window of odour delivery
#' @param odourCol colour of odour window (default pale red)
#' @param relabelfun function to apply to odour labels (default no relabelling)
#' @param IncludeChannels include numeric id of odour channel (e.g. for blanks)
#' @param PlotSpikes Whether to plot the spikes (default TRUE)
#' @param PlotDividers Plot the dividing lines between odours (default TRUE)
#' @param DividerCol the colour with which to plot dividing lines between odours
#'   (default black)
#' @param panel.first An \code{expression} to be evaluated after the plot axes 
#'   are set up but before any plotting takes place
#' @param panel.last An \code{expression} to be evaluated after spikes have been
#'   plotted
#' @param ... Additional parameters passed to plot
#' @author jefferis
#' @seealso \code{\link{CollectSpikesFromSweeps}, \link{fix.odd}} and 
#'   \code{\link{plot.default}} for graphical parameters
#' @export
#' @aliases plot.spiketimes
#' @examples
#' ## Plot time range 2-4s with odour pulse 2-3s for sweeps 0,1,3
#' PlotRasterFromSweeps(
#'   system.file('igor','spikes','nm20110811c0',package='gphys'),
#'   c(0,1,3),xlim=c(2000,4000),odourRange=c(2000,3000))
#' # Use rectangles for spikes instead
#' PlotRasterFromSweeps(
#'   system.file('igor','spikes','nm20110811c0',package='gphys'),
#'   c(0,1,3),xlim=c(0,4000),odourRange=c(2000,3000),dotwidth=20,pch='rect')
#' ## Fix a bad label, first define a function 
#' relabel=function(labels) {labels[labels=="fly"]="empty";labels}
#' ## and then use it
#' PlotRasterFromSweeps(
#'   system.file('igor','spikes','nm20110811c0',package='gphys'),
#'   c(0,1,3),relabelfun=relabel)
#' ## Example with block based organisation 
#' ## i.e. spike files sorted into different subdirs for each stimulus protocol
#' PlotRasterFromSweeps(
#'   system.file('igor','spikes','nm20120514c2',package='gphys'),
#'   subdir='BLOCKA',odourRange=c(2000,2500),xlim=c(0,5000))
#' ## Example of fixing one of Jonny's traces when channels were mixed up
#' fixVec=c(empty=31,IAA=30,cVA=29,PAA=27,`4ol`=26,ctr=25)
#' PlotRasterFromSweeps(
#'   system.file('igor','spikes','nm20110907c3',package='gphys'),
#'   subdir='BLOCKI',odourRange=c(2000,2500),xlim=c(0,5000),fixChannels=fixVec)
#' ## Imagine a double odour stimulation
#' PlotRasterFromSweeps(
#'   system.file('igor','spikes','nm20110907c3',package='gphys'),
#'   subdir='BLOCKI',odourRange=c(2000,2500,3000,3250),xlim=c(0,5000),
#'   fixChannels=fixVec)
PlotRasterFromSweeps<-function(sweepdir,sweeps,subdir='',subset=NULL,
  xlim=NULL,xaxis=TRUE,yaxis=TRUE,frame.plot=TRUE,xaxs='i',yaxs='i',
  main,sub,xlab='Time/ms', ylab='Odour',
  pch=22,dotcolour='black',dotsize=0.5,dotwidth=20,spikeheight=0.8,
  odourRange=NULL,odourCol=rgb(1,0.8,0.8,1),
  relabelfun=identity,fixChannels=NULL,IncludeChannels=FALSE,
  PlotSpikes=TRUE,PlotDividers=TRUE,DividerCol='black',
  panel.first=NULL,panel.last=NULL,...){
  if(inherits(sweepdir,'spiketimes')){
    rasterd=sweepdir
    if(!is.null(subset))
      rasterd=subset.spiketimes(rasterd)
  }
  else
    rasterd=CollectSpikesFromSweeps(sweepdir,sweeps,subdir=subdir,
        fixChannels=fixChannels,subset=subset)
  last_wave=max(sapply(rasterd,function(x) max(x$Wave,na.rm=TRUE)))
	
	if(is.null(xlim)){
		if(is.null(attr(rasterd,'xlim')))
			xlim=range(unlist(lapply(rasterd,'[[','Time')),na.rm = TRUE)
		else
			xlim=attr(rasterd,'xlim')
	}
	
	if(is.null(odourRange)){
		odourRange=attr(rasterd,'stimRange')
	}
	
  # set up plot area (but don't plot anything
	plot(NA,xlim=xlim,ylim=c(last_wave+1,0),ylab=ylab,xlab=xlab,axes=F,
      frame.plot=frame.plot,xaxs=xaxs,yaxs=yaxs,...)
	# show odour stim range
  if(!is.null(odourRange) && !is.na(odourRange)){
    if(!is.matrix(odourRange)) odourRange=matrix(odourRange,nrow=2)
    rect(odourRange[1,],par('usr')[3],odourRange[2,],par('usr')[4],col=odourCol,border=NA)
  }
  
  labels=relabelfun(attr(rasterd,'oddconf')$odour)
  if(IncludeChannels) labels=paste(labels,attr(rasterd,'oddconf')$chan)
	if(length(labels)>(last_wave+1))
	{
		warning("Dropping ", length(labels)-last_wave-1, " labels from odd config")
		labels = labels[seq(last_wave+1)]
	}
  if(yaxis)
    axis(side=2,at=seq(last_wave+1)-0.5,labels=labels,tick=F,las=1)
  if(xaxis)
    axis(1)
  nreps=length(rasterd)
  panel.first
  if(PlotSpikes){
    for(i in seq(rasterd)){
      yoff=i/(nreps+1)
      df=rasterd[[i]]
      if(pch=='rect'){
        # find the right dot height
        dotheight=spikeheight/(nreps+1)
        rect(df$Time,df$Wave+yoff-dotheight/2,df$Time+dotwidth,df$Wave+yoff+dotheight/2,col=dotcolour,border=NA)
      }
      else points(x=df$Time,y=df$Wave+yoff,pch=pch,col=NA,bg=dotcolour,cex=dotsize)
    }
  }
  panel.last
  # make dividers between waves if necessary
  if(last_wave>0 && PlotDividers){
    # fetch the actual plot range (not always the same as xlim)
    plot_xrange=par("usr")[1:2]
    for(i in seq(last_wave)){
      segments(plot_xrange[1],i,plot_xrange[2],i,col=DividerCol)
    }
  }

  if(missing(main)) main=""
  if(missing(sub)) sub=paste("Cell:",basename(attr(rasterd,'sweepdir')),
    "sweeps:",paste(attr(rasterd,'sweeps'),collapse=","))
  title(main=main,sub=sub)
}

#' Plot raster from spiketimes object
#' 
#' This overloads base R's plot and calls PlotRasterFromSweeps
#' @export
#' @param x A spiketimes object
#' @method plot spiketimes
#' @rdname PlotRasterFromSweeps
#' @seealso \code{\link{PlotRasterFromSweeps}, \link{spiketimes}}
#' @examples
#' options(gphys.datadir=system.file('igor','spikes',package='gphys'))
#' spikes=CollectSpikesFromSweeps('nm20120514c2',subdir='BLOCKB')
#' plot(spikes)
plot.spiketimes<-function(x, ...) PlotRasterFromSweeps(x, ...)

#' Read in Igor Pro exported text file of Nclamp spike times
#' 
#' The list of spiketimes has two columns, Time and Wave, where wave is the
#' number of the wave within each sweepfile containing the spike. xlim and
#' stimRange are kept as attributes that will be used for plots * fixChannels
#' expects a named vector of any channels that need to have different odour
#' names. This can be used to fix an error in the original ODD config file. * If
#' spike time txt files have been placed in a subdirectory, then that 
#' subdirectory must be specified using the \code{subdir} argument. * However it
#' is expected that the corresponding pxp and odd config files remain in the top
#' level directory for the cell.
#' @param sweepdir directory containing Nclamp pxp sweep files
#' @param sweeps Vector of sweeps to include (e.g. 1:7) or character regex which
#'   sweeps must match.
#' @param subdir subdirectory containing group of spike times txt files
#' @param xlim time range of sweeps
#' @param stimRange time range of stimulus
#' @param fixChannels Optional named integer vector that remaps some bad numeric
#'   channels to correct odours. FIXME shouldn't we fix channels as well.
#' @param subset Numeric vector of channels or character vector of odours
#' @return list (with class spiketimes) containing times for each sweep
#' @author jefferis
#' @export
#' @examples
#' \dontrun{
#' # Collect from absolute path (what you will probably typically do)
#' spikes=CollectSpikesFromSweeps(
#'   '/Volumes/JData/JPeople/Jonny/physiology/data/nm20120514c2',subdir='BLOCK B')
#' }
#' # If you have your data in a single folder hierarchy, you can that as the
#' # data directory.
#' # Here we set the data directory to folder containing gphys example data
#' options(gphys.datadir=system.file('igor','spikes',package='gphys'))
#' spikes=CollectSpikesFromSweeps('nm20120514c2',subdir='BLOCKB')
#' # Finally an example specifying the exact sweeps to load
#' spikes=CollectSpikesFromSweeps("nm20110811c0",c(0,1,3))
#' # and plotting them
#' plot(spikes,xlim=c(2000,4000),odourRange=c(2000,3000))
#' @importFrom tools md5sum
CollectSpikesFromSweeps<-function(sweepdir,sweeps,subdir='',xlim,stimRange,
    fixChannels=NULL,subset=NULL){
  if(!file.exists(sweepdir)){
    defaultdatadir=options('gphys.datadir')[[1]]
    if(!is.null(defaultdatadir)){
      sweepdir=file.path(defaultdatadir,sweepdir)
    }
  }
  fi=file.info(sweepdir)
  if(is.na(fi$isdir) || !fi$isdir){
    stop("Cannot read directory: ",sweepdir)
  }
  
  # Read in all spike times
	
  ff=dir(file.path(sweepdir,subdir),'^[0-9]{3}_SP_',full.names=TRUE)
  read_spikes<-function(f) {
    x=read.table(f,col.names=c("Time","Wave"),header=TRUE, na.strings='NAN')
    # Record first 3 digits of filename
    x$FileNum=substr(basename(f),1,3)
    x
  }
  rasterd=lapply(ff,read_spikes)
  names(rasterd)=substring(basename(ff),1,3)
  
  oddfiles=dir(sweepdir,pattern='_odd[_.]')
  names(oddfiles)=sub('.*_([0-9]{3})_odd.*','\\1',oddfiles)
  if(missing(sweeps)){
    sweeps=names(rasterd)
  } else {
    if(is.character(sweeps)){
      # assume we have been given a regex pattern to match against the odd 
      # config files saved in the current data directory.
      
      oddfiles=oddfiles[grepl(sweeps,oddfiles)]
      if(length(oddfiles)==0) 
        stop("No ODD config files match regex: ",sweeps)
      # Now extract the numeric ids of the relevant sweeps
      sweeps=names(oddfiles)      
    } else {
      # we've been given a numeric vector 1:2->c("001","002")
      sweeps=sprintf("%03d",sweeps)
      if(!all(sweeps%in%names(oddfiles))) 
        stop("Cannot find ODD config files for some sweeps: ",sweeps)
      oddfiles=oddfiles[sweeps]
    }
    
    if(all(sweeps%in%names(rasterd)))
      rasterd=rasterd[sweeps]
    else
      stop("Missing spike counts for sweeps: ",setdiff(sweeps,names(rasterd)))
  } 

  # Check that all ODD protocol(s) matching our chosen sweeps are the same
  # and then read in the first one
  oddfiles=file.path(sweepdir,oddfiles[sweeps])
  md5s=md5sum(oddfiles)
  if(length(unique(md5s))>1)
		stop("I don't yet know how to handle different odd config files")
  oddconf=read.odd(oddfiles[1])
  if(!is.null(fixChannels))
    oddconf=fix.odd(oddconf,fixChannels)
  attr(rasterd,'oddconf')=oddconf
  attr(rasterd,'sweeps')=sweeps
  attr(rasterd,'sweepdir')=sweepdir
	if(!missing(stimRange))
  	attr(rasterd,'stimRange')=stimRange
	if(!missing(xlim))
  	attr(rasterd,'xlim')=xlim
	
  class(rasterd)=c('spiketimes',class(rasterd))
  
  # now subset if required
  if(!is.null(subset)){
    rasterd=subset.spiketimes(rasterd,subset)
  }
  rasterd
}

#' Boxplot of spikes within a window (optionally less a baseline)
#' @inheritParams OdourResponseFromSpikes
#' @param freq Plot spike rate in Hz rather than counts (default FALSE)
#' @param PLOTFUN stripchart, boxplot or similar function (default stripchart)
#' @param ... Additional arguments passed on to PLOTFUN
#' @return results of plotfun (if any)
#' @author jefferis
#' @export
#' @family OdourResponse
#' @seealso CollectSpikesFromSweeps
#' @examples
#' \dontrun{ 
#' spikes=CollectSpikesFromSweeps(
#'   system.file('igor','spikes','nm20110914c4',package='gphys'),
#'   subdir='BLOCKI',sweeps=0:4)
#' ## stripchart
#' PlotOdourResponseFromSpikes(spikes,c(2200,2700),c(0,2000),pch=19,method='jitter',
#'  col=1:6)
#' ## boxplot, in Hz
#' PlotOdourResponseFromSpikes(spikes,c(2200,2700),c(0,2000),freq=TRUE,
#'  PLOTFUN=boxplot)
#' }
PlotOdourResponseFromSpikes<-function(spiketimes,responseWindow,baselineWindow=NULL,
  freq=FALSE,PLOTFUN=stripchart,...){
  # stack(bbdf)
  bbdf=OdourResponseFromSpikes(spiketimes = spiketimes,responseWindow = responseWindow,
      baselineWindow = baselineWindow, freq=freq)
  PLOTFUN(bbdf, xlab=ifelse(freq, 'Spike Frequency /Hz', 'Spike Count'), las=2, ...)
}

#' Produce table of spiking responses (optionally subtracting baseline)
#' 
#' Details: If baseline window is of different duration to response window
#' the baseline count is normalised to estimate the number of spikes that would have
#' occurred during the response window. ie if you have a 1s response window and a
#' 5s baseline window and you get 10 spikes in the response period and 5 spikes in
#' the baseline period, the response will be returned as 10-5/5 = 9 spikes.
#' @param spiketimes list of spiketimes collected by CollectSpikesFromSweeps
#' @param responseWindow vector of start and end time of odour response (in ms)
#' @param baselineWindow vector of start and end time of baseline period (in ms)
#' @param freq Calculate Spike rate in Hz rather than number of spikes per response window
#' @return dataframe with a column for each odour and row for each sweep
#' @author jefferis
#' @export
#' @family OdourResponse
#' @examples 
#' spikes=CollectSpikesFromSweeps(
#'   system.file('igor','spikes','nm20110914c4',package='gphys'),
#'   subdir='BLOCKI',sweeps=0:4)
#' od=OdourResponseFromSpikes(spikes,response=c(2200,2700),baseline=c(0,2000))
#' summary(od)
#' apply(od,2,function(x) c(mean=mean(x),sd=sd(x)))
#' 
#' # show baseline response frequency only (by treating that as response)
#' od2=OdourResponseFromSpikes(spikes,response=c(0,2000),freq=TRUE)
#' summary(od2)
OdourResponseFromSpikes<-function(spiketimes,responseWindow,baselineWindow=NULL,freq=FALSE){
  nreps=length(spiketimes)
  last_wave=max(sapply(spiketimes,function(x) max(x$Wave,na.rm=TRUE)))
  # note it would be preferable if we didn't have to invent sweep names here
  # but it is more robust to make them up now 
  if(is.null(names(spiketimes))) {
    names(spiketimes)=seq_along(spiketimes)
    warning("Making up fake sweep names for spiketimes",
            " (but don't worry this won't affect spike rates)")
  }
  # Want to collect a table which has rows for each odour
  spikess=do.call(rbind,spiketimes)
  spikess$Sweep=rep(names(spiketimes),sapply(spiketimes,nrow))
  
  responseTime=diff(responseWindow)
  responsecount=by(spikess$Time,
      list(factor(spikess$Sweep,levels=names(spiketimes)),factor(spikess$Wave)),
      function(t) sum(t>responseWindow[1] &t<responseWindow[2]))
  # replace NAs for each wave/sweep combo with an entry in empty_wave_sweeps
  # but not those wave/sweep combinations where this signalling NA from
  # Igor/NClamp is missing because those sweeps never actually happened
  # ie the odour was not presented!
  empty_wave_sweeps=spikess[is.na(spikess$Time) & !is.na(spikess$Wave),]
  for(i in seq_len(nrow(empty_wave_sweeps))){
    cur_wave=as.character(empty_wave_sweeps[i,'Wave'])
    cur_sweep=as.character(empty_wave_sweeps[i,'Sweep'])
    responsecount[cur_sweep,cur_wave]=0
  }
  if(!is.null(baselineWindow)){
    baselinecount=by(spikess$Time,
        list(factor(spikess$Sweep),factor(spikess$Wave)),
        function(t) sum(t>baselineWindow[1] &t<baselineWindow[2]))
    for(i in seq_len(nrow(empty_wave_sweeps))){
      cur_wave=as.character(empty_wave_sweeps[i,'Wave'])
      cur_sweep=as.character(empty_wave_sweeps[i,'Sweep'])
      baselinecount[cur_sweep,cur_wave]=0
    }
    baselineTime=diff(baselineWindow)
    responsecount=responsecount-baselinecount*responseTime/baselineTime
  }
  bbdf=as.data.frame(matrix(responsecount,ncol=ncol(responsecount)))
  colnames(bbdf)=make.unique(attr(spiketimes,'oddconf')$odour)
  if(freq) bbdf=bbdf/(responseTime/1000)
  bbdf
}

#' Add eg voltage traces to existing spike raster plot
#' 
#' First thing this does is scale waves to 0-1 range using scale.ts
#' Assumes that number of waves and number of boxes (odours)
#' on spike raster plot actually match. It doesn't check!
#' @details If col is a function then it will be called with the number of waves
#' @param waves an mts object
#' @param ylim min and max value to plot y axis of wave data (eg voltage)
#' @param col vector or function of colours that will be passed to \code{\link{lines}}
#' @param ... additional arguments passed to lines.ts function
#' @export
#' @seealso \code{\link{PlotRasterFromSweeps}},\code{\link{lines}}
#' @examples
#' \dontrun{
#' # First plot the rasters
#' spikes8=CollectSpikesFromSweeps('/Volumes/JData/JPeople/Shahar/Data/120308/nm20120308c0',8)
#' spike8_split=split(spikes8)
#' PlotRasterFromSweeps (spike8_split)
#' # Now plot the voltages
#' avgwaves=read.table(
#'   '/Volumes/JData/JPeople/Shahar/Data/120308/nm20120308c0/008_Avg_RG0_A0++.txt',
#'   header=T)
#' avgwavests=ts(avgwaves,start=0,freq=10)
#' AddLinesToRasterPlot(avgwavests,col='red')
#' # same but with rainbow colouring
#' PlotRasterFromSweeps (spike8_split)
#' AddLinesToRasterPlot(avgwavests,col='red')
#' # same but voltage lines underneath spikes
#' PlotRasterFromSweeps (spike8_split, panel.first=AddLinesToRasterPlot(avgwavests,col='red'))
#' # same but without spikes or dividers
#' PlotRasterFromSweeps (spike8_split,PlotSpikes=FALSE,PlotDividers=FALSE)
#' AddLinesToRasterPlot(avgwavests,col='red')
#' }
AddLinesToRasterPlot<-function(waves,ylim,col='black',...){
  scaled_waves=scale(waves, center=ylim[1], scale=diff(ylim))
  nwaves=ncol(scaled_waves)
  if(is.function(col)) col=col(nwaves)
  else if(length(col)==1 && nwaves>1){
    col=rep(col,nwaves)
  } else if(length(col)<nwaves){
    stop ("More waves (",nwaves,") than colours (",length(col),')')
  }
  # iterate over individual waves
  for(wnum in 1:nwaves){
    # nb - ... flips the y axis
    # wnum + ... shifts the plot in y to match up with the raster data
    lines(wnum - scaled_waves[,wnum],col=col[wnum],...)
  }
}
