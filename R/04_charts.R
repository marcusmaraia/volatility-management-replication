# All estimates and labels are read from generated CSVs, not embedded numeric arrays.
make_charts <- function(...) {
  read<-function(n)read.csv(n)
  t1<-read('results/tables/table1_computed.csv');t3<-read('results/tables/table3_computed.csv')
  t5<-read('results/tables/table5_computed.csv');ext<-read('results/tables/extension_2019_2025.csv')
  ht<-read('results/inference/historical_tests.csv');at<-read('results/inference/table3_HC0_alpha_tests.csv')
  et<-read('results/inference/extension_block_bootstrap.csv')
  fs<-c('MKT','SMB','HML');ord<-function(d)d[match(fs,d$factor),]
  t1<-ord(t1);t3<-ord(t3);t5<-ord(t5);at<-ord(at);et<-ord(et)
  cols<-c('#A9B6AE','#18744F');ink<-'#123C2A'
  start<-function(file){
    png(file.path('results/figures',file),width=1800,height=850,res=180,
      type=if(capabilities('aqua')) 'quartz' else 'cairo',bg='white',pointsize=12)
    par(mar=c(3.5,4.8,2.2,1),mgp=c(2.8,.7,0),tcl=-.25,
      col.axis=ink,col.lab=ink,fg='#8BA598',family='sans',las=1)
  }
  getp<-function(tab)ord(ht[ht$analysis==tab & ht$metric=='Sharpe',])$p_two_sided
  ptext<-function(p)ifelse(p<.001,'< .001',paste0('= ',sub('^0','',sprintf('%.3f',p))))
  pair<-function(file,a,b,leg,ylab,p,prefix='p (JK) '){
    start(file);on.exit(dev.off())
    span<-diff(range(c(a,b,0)));if(span==0)span<-1
    low<-min(c(a,b,0))-.32*span;high<-max(c(a,b,0))+.30*span
    values<-rbind(a,b)
    bp<-barplot(values,beside=TRUE,col=cols,border=NA,names.arg=fs,
      ylim=c(low,high),ylab=ylab,axes=FALSE,cex.names=1.05)
    ticks<-pretty(range(c(a,b,0)));abline(h=ticks,col='#EDF1EE',lwd=.7)
    barplot(values,beside=TRUE,col=cols,border=NA,axes=FALSE,axisnames=FALSE,add=TRUE)
    axis(2,at=ticks,col='#BCCFC4',col.axis=ink);abline(h=0,col='#8BA598',lwd=.8)
    for(i in 1:2){v<-values[i,];text(bp[i,],v+ifelse(v>=0,.025,-.025)*span,
      sprintf('%.3f',v),pos=ifelse(v>=0,3,1),cex=.85,col=if(i==2)cols[2] else ink)}
    legend('topright',legend=leg,fill=cols,border=NA,bty='n',horiz=TRUE,cex=.9,text.col=ink)
    text(colMeans(bp),low+.045*span,paste0(prefix,ptext(p)),cex=.82,col=ink)
  }
  pair('01_direct_sharpe.png',t1$original_SR,t1$managed_SR,c('Unmanaged','Managed'),'Annualized Sharpe ratio',getp('Table 1'))
  pair('03_realtime_sharpe.png',t5$original_SR,t5$combo_SR,c('Original only','Original + managed'),'Annualized Sharpe ratio',getp('Table 5'))
  eu<-ord(ext[ext$strategy=='unmanaged',]);en<-ord(ext[ext$strategy=='managed_capped_net',])
  pair('04_extension_sharpe.png',eu$SR,en$SR,c('Unmanaged','Capped, net of costs'),'Annualized Sharpe ratio',et$p_two_sided,'p (block) ')
  start('02_spanning_alpha.png')
  e<-t3$alpha_ann_pct;lo<-e-qnorm(.975)*t3$alpha_SE_HC0_ann_pct;hi<-e+qnorm(.975)*t3$alpha_SE_HC0_ann_pct
  lim<-range(c(0,lo,hi));span<-diff(lim)
  plot(1:3,e,type='n',xlim=c(.5,3.5),ylim=c(lim[1]-.27*span,lim[2]+.15*span),xaxt='n',xlab='',ylab='Annualized alpha (%)',bty='n')
  abline(h=pretty(lim),col='#EDF1EE');abline(h=0,lty=2,col='#729784')
  arrows(1:3,lo,1:3,hi,angle=90,code=3,length=.08,lwd=2,col=cols[2]);points(1:3,e,pch=19,cex=1.5,col=cols[2])
  axis(1,at=1:3,labels=fs,tick=FALSE);text(1:3,lim[1]-.18*span,paste0('p (HC0) ',ptext(at$p_two_sided)),cex=.85,col=ink)
  dev.off()
  start('05_extension_drawdowns.png');dd<-rbind(-100*eu$max_drawdown,-100*en$max_drawdown)
  bp<-barplot(dd,beside=TRUE,col=cols,border=NA,names.arg=fs,ylim=c(0,max(dd)*1.35),ylab='Maximum drawdown magnitude (%)',axes=FALSE)
  axis(2);abline(h=pretty(c(0,max(dd))),col='#EDF1EE')
  barplot(dd,beside=TRUE,col=cols,border=NA,axes=FALSE,axisnames=FALSE,add=TRUE)
  text(bp,dd,sprintf('%.1f%%',dd),pos=3,cex=.85,col=ink)
  legend('topleft',legend=c('Unmanaged','Capped, net'),fill=cols,border=NA,bty='n',horiz=TRUE,cex=.9,text.col=ink);dev.off()
}
