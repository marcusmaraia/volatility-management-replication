# Read the preserved 202609 French archives; no automatic network downloads.
read_french <- function(path,daily=FALSE) {
  if (grepl('\\.zip$',path,ignore.case=TRUE)) {
    listing <- unzip(path,list=TRUE)$Name
    csv <- grep('\\.(csv|txt)$',listing,ignore.case=TRUE,value=TRUE)[1]
    if (is.na(csv)) stop('No CSV or TXT found in ',path)
    lines <- readLines(unz(path,csv),warn=FALSE)
  } else lines <- readLines(path,warn=FALSE)
  # Data records are comma-separated; ignore header, annual section and footnotes.
  regex <- if(daily) '^\\s*[0-9]{8}\\s*,' else '^\\s*[0-9]{6}\\s*,'
  ix <- grep(regex,lines)
  if (!length(ix)) stop('No valid factor rows found in ',path)
  # First contiguous monthly/daily block only; protects against annual rows in monthly archive.
  cut <- which(diff(ix)>1)
  if(length(cut)) ix <- ix[seq_len(cut[1])]
  chunks <- strsplit(lines[ix],',',fixed=TRUE)
  chunks <- Filter(function(x) length(x)>=5,chunks)
  m <- do.call(rbind,lapply(chunks,function(x) trimws(x[1:5])))
  dt <- as.character(m[,1]); yrmo <- substr(dt,1,6)
  d <- data.frame(ym=as.integer(yrmo), MKT=suppressWarnings(as.numeric(m[,2]))/100, SMB=suppressWarnings(as.numeric(m[,3]))/100, HML=suppressWarnings(as.numeric(m[,4]))/100, RF=suppressWarnings(as.numeric(m[,5]))/100)
  if(daily) d$date <- as.Date(dt,format='%Y%m%d')
  for(n in c('MKT','SMB','HML','RF')) d[[n]][abs(d[[n]])>5] <- NA_real_
  d <- d[!is.na(d$ym) & stats::complete.cases(d[,c('MKT','SMB','HML')]),,drop=FALSE]
  if(anyDuplicated(if(daily)d$date else d$ym)) stop('Duplicate dates in ',path)
  d[order(if(daily)d$date else d$ym),,drop=FALSE]
}


prepare_data <- function() {
  month <- read_french('data/raw/F-F_Research_Data_Factors.zip')
  day <- read_french('data/raw/F-F_Research_Data_Factors_daily.zip', daily=TRUE)
  next_month <- function(x) ifelse(x %% 100 == 12, x+89L, x+1L)
  for (f in c('MKT','SMB','HML')) {
    v <- tapply(day[[f]]^2, day$ym, function(x) 22*mean(x))
    month[[paste0('v_',f)]] <- as.numeric(v[match(month$ym,as.integer(names(v)))])
    lagv <- c(NA, head(month[[paste0('v_',f)]],-1))
    gaps <- which(tail(month$ym,-1)!=next_month(head(month$ym,-1)))
    if(length(gaps)) lagv[gaps+1] <- NA_real_
    month[[paste0('vlag_',f)]] <- lagv
    month[[paste0('raw_',f)]] <- month[[f]]/lagv
  }
  stopifnot(!anyDuplicated(month$ym), !anyDuplicated(day$date))
  month
}
