# Selected historical Tables 1, 3 Panel A, and 5 Panel A; preliminary extension.
sr <- function(x) if(length(x)>2 && stats::sd(x)>0) sqrt(12)*mean(x)/stats::sd(x) else NA_real_
cer <- function(x,gamma=5) if(length(x)>2) 1200*(mean(x)-gamma/2*stats::var(x)) else NA_real_
clamp <- function(x,bound=5) max(-bound,min(bound,x))
hc0 <- function(fit) {
  X <- model.matrix(fit); u <- stats::residuals(fit)
  bread <- solve(crossprod(X)); meat <- crossprod(X,X*u^2)
  bread %*% meat %*% bread
}
scale_c <- function(f,raw) {
  ok <- is.finite(f)&is.finite(raw)
  if(sum(ok)<10 || sd(raw[ok])==0) return(NA_real_)
  sd(f[ok])/sd(raw[ok])
}
perf <- function(x, prefix='') {
  x <- x[is.finite(x)]; if(length(x)<3) stop('Too few observations')
  c(n=length(x),mean_ann_pct=1200*mean(x),sd_ann_pct=100*sqrt(12)*sd(x),SR=sr(x),CER_pct=cer(x))
}
compare <- function(estimate,reference,keys) {
  d <- merge(estimate,reference,by='factor',suffixes=c('_computed','_published'))
  for(k in keys) d[[paste0(k,'_gap')]] <- d[[paste0(k,'_computed')]]-d[[paste0(k,'_published')]]
  d
}

# Table 1: full-sample SD matched using c* = sd(f) / sd(f / v_lag).
# In-sample comparisons are DESCRIPTIVE and use future sample for normalization by design.
run_table1 <- function(dat) {
  ans <- list(); expanded <- list()
  for(f in factors) {
    keep <- is.finite(dat[[f]]) & is.finite(dat[[paste0('raw_',f)]])
    d <- dat[keep,,drop=FALSE]; cstar <- scale_c(d[[f]],d[[paste0('raw_',f)]])
    d$managed <- cstar*d[[paste0('raw_',f)]]
    a <- perf(d[[f]]); b <- perf(d$managed)
    ans[[f]] <- data.frame(factor=f,n=length(d$managed),c_star=cstar,original_mean_ann_pct=a['mean_ann_pct'],original_sd_ann_pct=a['sd_ann_pct'],original_SR=a['SR'],managed_mean_ann_pct=b['mean_ann_pct'],managed_sd_ann_pct=b['sd_ann_pct'],managed_SR=b['SR'],delta_SR=b['SR']-a['SR'],correlation=cor(d[[f]],d$managed),exposure_p01=unname(quantile(cstar/d[[paste0('vlag_',f)]],.01)),exposure_p50=unname(quantile(cstar/d[[paste0('vlag_',f)]],.50)),exposure_p99=unname(quantile(cstar/d[[paste0('vlag_',f)]],.99)))
    d$factor <- f; d$managed_factor <- d$managed; d$weight <- cstar/d[[paste0('vlag_',f)]]; expanded[[f]] <- d
  }
  list(table=do.call(rbind,ans),series=expanded)
}

# Table 3: spanning regression with manually computed White HC0 covariance.
run_table3 <- function(tab1) {
  ans <- list()
  for(f in factors) {
    d <- tab1$series[[f]]; fit <- lm(managed_factor~original,data=transform(d,original=d[[f]]))
    se <- sqrt(diag(hc0(fit))); a <- unname(coef(fit)[1]); b <- unname(coef(fit)[2]);
    Sigma <- cov(cbind(d[[f]],d$managed_factor)); mu <- colMeans(cbind(d[[f]],d$managed_factor))
    optimal <- tryCatch(solve(Sigma,mu),error=function(e) qr.solve(Sigma+diag(1e-12,2),mu))
    xret <- as.vector(cbind(d[[f]],d$managed_factor)%*%optimal)
    ans[[f]] <- data.frame(factor=f,n=nrow(d),alpha_ann_pct=1200*a,alpha_t=a/se[1],beta=b,adj_R2=summary(fit)$adj.r.squared,appraisal_ratio=sqrt(12)*a/summary(fit)$sigma,ex_post_SR=sr(xret),alpha_SE_HC0_ann_pct=1200*se[1])
  }
  do.call(rbind,ans)
}

# Table 5 Panel A, equations (15)-(16): expanding window, K = 120,
# FULL factor position y_t = x_{sigma,t} * c_t / lagged variance + x_t.
# Follow Section 4.3.1, Eq. (16), with the stated cap |y_t| <= 5.
# Table 5 caption describes risky-weight leverage differently; see reports/REPLICATION_AUDIT.md.
# At every t, c_t and portfolio moments are reestimated only on dates < t.
run_table5 <- function(dat,K=120,gamma=5,limit=5) {
  ans <- list(); all_paths <- list()
  for(f in factors) {
    dd <- dat[is.finite(dat[[paste0('raw_',f)]]) & is.finite(dat[[f]]),,drop=FALSE]
    if(nrow(dd)<=K+12) stop('Insufficient history for ',f)
    N <- nrow(dd); combo <- original <- oracle <- rep(NA_real_,N); exp_combo <- exp_orig <- rep(NA_real_,N)
    raw <- dd[[paste0('raw_',f)]]; r <- dd[[f]]; v <- dd[[paste0('vlag_',f)]]
    for(t in (K+1):N) {
      ix <- seq_len(t-1)
      c_t <- scale_c(r[ix],raw[ix])
      scaled_train <- raw[ix]*c_t
      Z <- cbind(scaled_train,r[ix]); mu <- colMeans(Z); S <- cov(Z)
      # The paper's two-asset unrestricted mean-variance weights (Eq. 15).
      weights <- tryCatch(solve(S,mu/gamma),error=function(e) solve(S+diag(1e-10,2),mu/gamma))
      y_combo <- clamp(weights[1]*c_t/v[t]+weights[2],limit)
      y_original <- clamp(mean(r[ix])/(gamma*var(r[ix])),limit)
      combo[t] <- y_combo*r[t]; original[t] <- y_original*r[t]
      exp_combo[t] <- y_combo; exp_orig[t] <- y_original
    }
    # Ex post optimal (hindsight) weights on identical OOS evaluation period,
    # separately normalized at evaluation sample for reference benchmark.
    oos <- (K+1):N; cstar <- scale_c(r[oos],raw[oos]); Z <- cbind(cstar*raw[oos],r[oos]);
    wstar <- tryCatch(solve(cov(Z),colMeans(Z)/gamma),error=function(e) solve(cov(Z)+diag(1e-10,2),colMeans(Z)/gamma))
    ystar <- wstar[1]*cstar/v[oos]+wstar[2]; oracle[oos] <- ystar*r[oos]
    ans[[f]] <- data.frame(factor=f,n_train=K,n_eval=length(oos),first_eval=dd$ym[oos[1]],last_eval=dd$ym[N],combo_SR=sr(combo[oos]),original_SR=sr(original[oos]),delta_SR=sr(combo[oos])-sr(original[oos]),combo_CER_pct=cer(combo[oos],gamma),original_CER_pct=cer(original[oos],gamma),delta_CER_pct=cer(combo[oos],gamma)-cer(original[oos],gamma),ex_post_SR=sr(oracle[oos]))
    all_paths[[f]] <- data.frame(ym=dd$ym[oos],factor=f,original_excess=r[oos],combo_excess=combo[oos],original_only_excess=original[oos],oracle_excess=oracle[oos],y_combo=exp_combo[oos],y_original=exp_orig[oos])
  }
  list(table=do.call(rbind,ans),paths=do.call(rbind,all_paths))
}

# Preliminary extension (NOT a published result): 2019-2025 holdout.
# Calibration uses observations <= 2018-12. No re-tuning on evaluation data.
# Trade cost is bps * absolute change in factor exposure; this is a proxy,
# particularly for SMB/HML's underlying constituent-level transaction costs.
run_extension <- function(dat,train_start=196307L,train_end=201812L,test_start=201901L,test_end=202512L,
                          cap=2,cost_bps=10) {
  out <- list(); paths <- list()
  for(f in factors) {
    valid <- dat[is.finite(dat[[paste0('raw_',f)]]) & is.finite(dat[[f]]),,drop=FALSE]
    tr <- valid[valid$ym>=train_start & valid$ym<=train_end,,drop=FALSE]; te <- valid[valid$ym>=test_start & valid$ym<=test_end,,drop=FALSE]
    if(nrow(tr)<120 || nrow(te)<12) stop('Not enough extension training/eval data for ',f)
    ctrain <- scale_c(tr[[f]],tr[[paste0('raw_',f)]])
    exposure_unc <- ctrain/te[[paste0('vlag_',f)]]
    exposure_cap <- pmax(-cap,pmin(cap,exposure_unc))
    # Assume a position is established at first evaluation month from cash (previous exposure=0).
    turnover <- abs(exposure_cap-c(0,head(exposure_cap,-1)))
    cost <- turnover*cost_bps/10000
    rawret <- te[[f]]; gross <- exposure_unc*rawret; capped <- exposure_cap*rawret; net <- capped-cost
    variants <- list(unmanaged=rawret,managed_unconstrained=gross,managed_capped_gross=capped,managed_capped_net=net)
    for(nm in names(variants)) {
      x <- variants[[nm]]; wealth <- cumprod(1+x)
      out[[paste(f,nm)]] <- data.frame(factor=f,strategy=nm,n=nrow(te),mean_ann_pct=1200*mean(x),sd_ann_pct=100*sqrt(12)*sd(x),SR=sr(x),CER_pct=cer(x),max_drawdown= min(wealth/cummax(c(1,wealth))[-1]-1),avg_monthly_turnover=if(nm=='managed_capped_net')mean(turnover) else NA_real_,cap=cap,cost_bps=cost_bps)
    }
    paths[[f]] <- data.frame(ym=te$ym,factor=f,unmanaged=rawret,uncapped=gross,capped_gross=capped,capped_net=net,uncapped_exposure=exposure_unc,capped_exposure=exposure_cap,turnover=turnover,cost=cost)
  }
  list(table=do.call(rbind,out),paths=do.call(rbind,paths))
}

