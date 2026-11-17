check_results <- function(month,t1,t3,t5,ext,tests,from_raw=TRUE) {
  stopifnot(nrow(month)==1203L,range(month$ym)==c(192607L,202609L),!anyDuplicated(month$ym))
  nextmonth<-function(x)ifelse(x%%100==12,x+89L,x+1L)
  stopifnot(all(tail(month$ym,-1)==nextmonth(head(month$ym,-1))))
  for(f in c('MKT','SMB','HML')) {
    v<-month[[paste0('v_',f)]];vl<-month[[paste0('vlag_',f)]];raw<-month[[paste0('raw_',f)]];ok<-is.finite(raw)
    stopifnot(isTRUE(all.equal(tail(vl,-1),head(v,-1),check.attributes=FALSE)),
      max(abs(raw[ok]-month[[f]][ok]/vl[ok])/pmax(1,abs(raw[ok])))<1e-12)
    d<-t1$series[[f]];stopifnot(nrow(d)==1085L,abs(sd(d[[f]])-sd(d$managed))<1e-12)
    fit<-lm(d$managed~d[[f]]);X<-model.matrix(fit);u<-resid(fit)
    V<-solve(t(X)%*%X)%*%(t(X)%*%diag(u^2)%*%X)%*%solve(t(X)%*%X)
    j<-match(f,t3$factor);stopifnot(abs(sqrt(V[1,1])*1200-t3$alpha_SE_HC0_ann_pct[j])<1e-10)
    q<-t5$paths[t5$paths$factor==f,]
    stopifnot(nrow(q)==965L,min(q$ym)==193608L,max(q$ym)==201612L,
      max(abs(q$y_combo))<=5,max(abs(q$y_original))<=5,
      max(abs(q$combo_excess-q$y_combo*q$original_excess))<1e-12)
    for(ym in q$ym[c(1,nrow(q))]) {
      train<-d[d$ym<ym,];at<-d[d$ym==ym,];c0<-scale_c(train[[f]],train[[paste0('raw_',f)]])
      Z<-cbind(c0*train[[paste0('raw_',f)]],train[[f]]);w<-solve(cov(Z),colMeans(Z)/5)
      target<-clamp(w[1]*c0/at[[paste0('vlag_',f)]]+w[2],5)
      stopifnot(abs(target-q$y_combo[q$ym==ym])<1e-10)
    }
    # Independent numerator formula, paper footnote 8.
    x<-d[[f]];y<-d$managed;n<-length(x);sx<-sd(x);sy<-sd(y);mx<-mean(x);my<-mean(y);cxy<-cov(x,y)
    theta<-(2*sx^2*sy^2-2*sx*sy*cxy+.5*mx^2*sy^2+.5*my^2*sx^2-mx*my*cxy^2/(sx*sy))/n
    stopifnot(abs((sx*my-sy*mx)/sqrt(theta)-jk_test(x,y)$z)<1e-10)
    # Explicit moment covariance matrix, paper footnote 19.
    S<-matrix(0,4,4);S[1:2,1:2]<-matrix(c(var(x),cxy,cxy,var(y)),2)
    S[3:4,3:4]<-matrix(c(2*var(x)^2,2*cxy^2,2*cxy^2,2*var(y)^2),2)
    g<-c(-1,1,5/2,-5/2);se<-sqrt(drop(t(g)%*%S%*%g)/n)*1200
    stopifnot(abs(se-dgu_test(x,y)$SE_annual)<1e-10)
    e<-ext$paths[ext$paths$factor==f,]
    stopifnot(nrow(e)==84L,min(e$ym)==201901L,max(e$ym)==202512L,max(abs(e$capped_exposure))<=2,
      max(abs(e$capped_net-(e$capped_exposure*e$unmanaged-e$cost)))<1e-12,
      max(abs(e$cost-.001*abs(e$capped_exposure-c(0,head(e$capped_exposure,-1)))))<1e-12)
    tr<-month[month$ym>=196307 & month$ym<=201812,]
    expected<-scale_c(tr[[f]],tr[[paste0('raw_',f)]])/month[[paste0('vlag_',f)]][match(e$ym,month$ym)]
    stopifnot(max(abs(expected-e$uncapped_exposure))<1e-10)
  }
  if(from_raw) {
    # External check against the numbers printed in the original proposal.
    m<-month[month$ym>=196307 & month$ym<=202512,]
    d<-read_french('data/raw/F-F_Research_Data_Factors_daily.zip',TRUE)
    d<-d[d$ym>=196307 & d$ym<=202512,]
    rv<-tapply(d$MKT,d$ym,function(x)100*sqrt(252*mean((x-mean(x))^2)))
    z<-cbind(m[,c('MKT','SMB','HML','RF')]*100,vol=as.numeric(rv[as.character(m$ym)]))
    actual<-t(vapply(z,function(x)c(mean(x),sd(x),min(x),max(x)),numeric(4)))
    reference<-matrix(c(.594,4.460,-23.190,16.110,
      .145,3.022,-17.390,21.340,.286,2.971,-13.830,12.860,
      .363,.261,0,1.350,13.450,8.378,2.703,90.727),nrow=5,byrow=TRUE)
    stopifnot(nrow(m)==750L,nrow(d)==15731L,max(abs(round(actual,3)-reference))<1e-9)
  }
  stopifnot(all(is.finite(tests$historical$p_two_sided)),all(tests$historical$p_two_sided>=0 & tests$historical$p_two_sided<=1))
  # Prevent stale prose from claiming the frozen snapshot has different findings.
  hs<-tests$historical[tests$historical$metric=='Sharpe',]
  an<-tests$alpha;un<-ext$table[ext$table$strategy=='unmanaged',]
  ne<-ext$table[ext$table$strategy=='managed_capped_net',]
  ne<-ne[match(un$factor,ne$factor),]
  narrative_ok<-all(hs$p_two_sided>.05) && all(t5$table$delta_SR<0) &&
    an$p_two_sided[an$factor=='MKT']<.05 && all(an$p_two_sided[an$factor!='MKT']>.05) &&
    all(ne$SR<un$SR) && all(abs(ne$max_drawdown)<abs(un$max_drawdown))
  if(!narrative_ok)stop('Findings changed: review the slide/script conclusions before exporting.')
  writeLines(c(if(from_raw)'PASS: raw reconstruction equals preserved processed snapshot.' else 'SKIP: raw reconstruction was not run in --from-processed mode.',
    'PASS: continuity, lag identities, sample sizes, volatility matching.',
    'PASS: HC0 matrix, equivalent JK formula, DGU moment covariance.',
    'PASS: qualitative slide/script conclusions agree with the computed snapshot.',
    'PASS: recursive first/last weights use past data; caps and costs.',
    'PASS: extension calibration matches July 1963-December 2018.',
    if(from_raw)'PASS: original proposal counts and descriptive table match at reported precision.' else 'SKIP: proposal raw-data descriptive check in processed-only mode.',
    'LIMIT: no claim of paper-author data-vintage or source-code identity.'),'reports/validation.txt')
}
