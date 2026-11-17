# Transcribed from published Tables 1, 3 Panel A, 5 Panel A; checked against PDF.
factors <- c('MKT','SMB','HML')
ref_t1 <- data.frame(factor=factors, original_SR=c(.42,.23,.40), managed_SR=c(.51,.08,.38), delta_SR=c(.09,-.15,-.02), original_mean_ann_pct=c(7.80,2.57,4.84), original_sd_ann_pct=c(18.61,11.12,12.14), managed_mean_ann_pct=c(9.55,.86,4.64), managed_sd_ann_pct=c(18.61,11.12,12.14), published=TRUE)
ref_t3 <- data.frame(factor=factors, alpha_ann_pct=c(4.63,-.76,1.87), alpha_t=c(3.08,-.87,1.88), beta=c(.63,.63,.57), adj_R2=c(.40,.40,.33), ex_post_SR=c(.53,.25,.44), published=TRUE)
ref_t5 <- data.frame(factor=factors, combo_SR=c(.42,.14,.38), original_SR=c(.46,.19,.43), delta_SR=c(-.04,-.06,-.06), combo_CER_pct=c(1.56,0,1.41), original_CER_pct=c(1.75,.38,1.61), delta_CER_pct=c(-.19,-.37,-.20), ex_post_SR=c(.53,.26,.50), published=TRUE)

ref_t1$paper_SR_p <- c(.30,.09,.86)
ref_t5$paper_SR_p <- c(.64,.37,.41)
ref_t5$paper_CER_p <- c(.83,.27,.73)
