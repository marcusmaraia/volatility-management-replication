# Paper-aligned historical inference; all inputs are monthly decimal returns.
# Sharpe: Jobson-Korkie with Memmel correction, paper footnote 8.
# CER: DeMiguel-Garlappi-Uppal normal approximation, paper footnote 19.
jk_test <- function(x,y) {
  ok <- is.finite(x)&is.finite(y); x<-x[ok]; y<-y[ok]; n<-length(x)
  stopifnot(n>2,sd(x)>0,sd(y)>0)
  a<-mean(x)/sd(x); b<-mean(y)/sd(y); rho<-cor(x,y)
  variance<-(2*(1-rho)+0.5*(a*a+b*b)-rho*rho*a*b)/n
  se<-sqrt(variance); z<-(b-a)/se
  data.frame(n=n,estimate=sqrt(12)*(b-a),SE_annual=sqrt(12)*se,z=z,
             p_two_sided=2*pnorm(-abs(z)),
             CI_low=sqrt(12)*(b-a-qnorm(.975)*se),
             CI_high=sqrt(12)*(b-a+qnorm(.975)*se))
}
dgu_test <- function(x,y,gamma=5) {
  ok<-is.finite(x)&is.finite(y);x<-x[ok];y<-y[ok];n<-length(x)
  vx<-var(x);vy<-var(y);cxy<-cov(x,y)
  # Delta method for mean-minus-(gamma/2)*variance under normal moments.
  v<-(vx+vy-2*cxy + (gamma^2/2)*(vx^2+vy^2-2*cxy^2))/n
  estimate<-mean(y)-mean(x)-(gamma/2)*(vy-vx);se<-sqrt(v);z<-estimate/se
  data.frame(n=n,estimate=1200*estimate,SE_annual=1200*se,z=z,
             p_two_sided=2*pnorm(-abs(z)),
             CI_low=1200*(estimate-qnorm(.975)*se),
             CI_high=1200*(estimate+qnorm(.975)*se))
}
# Supplementary extension test only; not the published historical-table test.
paired_boot <- function(x,y,B=5000L,L=12L) {
  good<-is.finite(x)&is.finite(y);x<-x[good];y<-y[good];n<-length(x)
  observed<-sr(y)-sr(x)
  boot<-replicate(B,{
    starts<-sample.int(n,ceiling(n/L),replace=TRUE)
    ix<-unlist(lapply(starts,function(s)((s-1L+seq_len(L)-1L)%%n)+1L),use.names=FALSE)[seq_len(n)]
    sr(y[ix])-sr(x[ix])
  })
  ci<-quantile(boot,c(.025,.975),names=FALSE)
  data.frame(n=n,estimate=observed,CI_low=ci[1],CI_high=ci[2],
    p_two_sided=(1+sum(abs(boot-observed)>=abs(observed)))/(B+1),blocks=L,replicates=B)
}
run_inference <- function(t1,t3,t5,ext) {
  rows<-list()
  for(f in c('MKT','SMB','HML')) {
    d<-t1$series[[f]];q<-t5$paths[t5$paths$factor==f,]
    rows[[paste0(f,'1')]]<-cbind(analysis='Table 1',factor=f,metric='Sharpe',method='JK-Memmel',jk_test(d[[f]],d$managed))
    rows[[paste0(f,'5')]]<-cbind(analysis='Table 5',factor=f,metric='Sharpe',method='JK-Memmel',jk_test(q$original_only_excess,q$combo_excess))
    rows[[paste0(f,'c')]]<-cbind(analysis='Table 5',factor=f,metric='CER annual pct',method='DGU-normal',dgu_test(q$original_only_excess,q$combo_excess))
  }
  hist_tests<-do.call(rbind,rows);rownames(hist_tests)<-NULL
  alpha<-data.frame(factor=t3$factor,n=t3$n,alpha_annual_pct=t3$alpha_ann_pct,
     HC0_SE_annual_pct=t3$alpha_SE_HC0_ann_pct,t=t3$alpha_t,
     p_two_sided=2*pnorm(-abs(t3$alpha_t)),
     CI_low_annual_pct=t3$alpha_ann_pct-qnorm(.975)*t3$alpha_SE_HC0_ann_pct,
     CI_high_annual_pct=t3$alpha_ann_pct+qnorm(.975)*t3$alpha_SE_HC0_ann_pct)
  RNGkind("Mersenne-Twister","Inversion","Rejection")
  set.seed(5200)
  extension<-do.call(rbind,lapply(c('MKT','SMB','HML'),function(f){
    e<-ext$paths[ext$paths$factor==f,];cbind(factor=f,paired_boot(e$unmanaged,e$capped_net))
  }))
  list(historical=hist_tests,alpha=alpha,extension=extension)
}
