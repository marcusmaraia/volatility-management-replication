# Generate computed slide values, tables, and the results summary.
make_documents <- function(t1,t3,t5,ext,tests) {
  vals<-character();fs<-c('MKT','SMB','HML')
  put<-function(k,x,d=3,plus=FALSE) {
    vals[k]<<-if(plus)sprintf(paste0('%+.',d,'f'),x) else sprintf(paste0('%.',d,'f'),x)
  }
  for(f in fs) {
    a<-t1$table[t1$table$factor==f,];b<-t3[t3$factor==f,];c<-t5$table[t5$table$factor==f,]
    h<-tests$historical[tests$historical$factor==f,];e<-tests$extension[tests$extension$factor==f,]
    net<-ext$table[ext$table$factor==f & ext$table$strategy=='managed_capped_net',]
    u<-ext$table[ext$table$factor==f & ext$table$strategy=='unmanaged',]
    put(paste0(f,'OrigOne'),a$original_SR);put(paste0(f,'ManagedOne'),a$managed_SR)
    put(paste0(f,'DeltaOne'),a$delta_SR,plus=TRUE)
    put(paste0(f,'Alpha'),b$alpha_ann_pct);put(paste0(f,'AlphaT'),b$alpha_t)
    put(paste0(f,'AlphaP'),2*pnorm(-abs(b$alpha_t)),4)
    put(paste0(f,'OneP'),h$p_two_sided[h$analysis=='Table 1'])
    put(paste0(f,'FiveP'),h$p_two_sided[h$analysis=='Table 5' & h$metric=='Sharpe'])
    put(paste0(f,'OrigFive'),c$original_SR);put(paste0(f,'ComboFive'),c$combo_SR)
    put(paste0(f,'NetSR'),net$SR);put(paste0(f,'BlockP'),e$p_two_sided)
    put(paste0(f,'UnmanagedDD'),-100*u$max_drawdown,1);put(paste0(f,'NetDD'),-100*net$max_drawdown,1)
  }
  writeLines(paste0('\\newcommand{\\',names(vals),'}{',vals,'}'),'presentation/source/values.tex')
  # Editable table rows use the same computed objects as the CSVs and charts.
  row<-function(label,version,x,d=3)paste0(label,' & ',version,' & ',paste(sprintf(paste0('%.',d,'f'),x),collapse=' & '),' \\\\')
  a<-t1$table[match(fs,t1$table$factor),];b<-t3[match(fs,t3$factor),];c<-t5$table[match(fs,t5$table$factor),]
  rows<-c(row('Table 1: original SR','computed',a$original_SR),row('Table 1: managed SR','computed',a$managed_SR),
    row('Table 1: managed SR','published',ref_t1$managed_SR,2),'\\midrule',
    row('Table 3: alpha (ann. \\%)','computed',b$alpha_ann_pct),row('Table 3: alpha (ann. \\%)','published',ref_t3$alpha_ann_pct,2),'\\midrule',
    row('Table 5: combo SR','computed',c$combo_SR),row('Table 5: combo SR','published',ref_t5$combo_SR,2),
    row('Table 5: original SR','computed',c$original_SR),row('Table 5: original SR','published',ref_t5$original_SR,2))
  writeLines(c('\\begin{tabular}{llrrr}\\toprule', 'Metric & Version & MKT & SMB & HML \\\\ \\midrule', rows, '\\bottomrule\\end{tabular}'),'presentation/source/comparison_rows.tex')
  testrow<-function(label,p,d=3)paste0(label,' & ',paste(sprintf(paste0('%.',d,'f'),p),collapse=' & '),' \\\\')
  getp<-function(tab,metric='Sharpe') {
    h<-tests$historical[tests$historical$analysis==tab & tests$historical$metric==metric,]
    h$p_two_sided[match(fs,h$factor)]
  }
  rows<-c(testrow('Table 1: Sharpe (JK)',getp('Table 1')),
    testrow('Table 3: alpha (HC0)',tests$alpha$p_two_sided[match(fs,tests$alpha$factor)],4),
    testrow('Table 5: Sharpe (JK)',getp('Table 5')),
    testrow('Table 5: CER (DGU)',getp('Table 5','CER annual pct')),
    testrow('Extension: Sharpe (block)',tests$extension$p_two_sided[match(fs,tests$extension$factor)]))
  writeLines(c('\\begin{tabular}{lrrr}\\toprule', 'Two-sided $p$-value & MKT & SMB & HML \\\\ \\midrule', rows, '\\bottomrule\\end{tabular}'),'presentation/source/inference_rows.tex')
  # Brief results summary replaces redundant historical reports and drafts.
  result<-c('# Computed results','',
    '| Factor | Original SR | Managed SR | Alpha (annual %) | Real-time original SR | Real-time combo SR |',
    '| --- | ---: | ---: | ---: | ---: | ---: |')
  for(i in seq_along(fs))result<-c(result,sprintf('| %s | %.3f | %.3f | %.3f | %.3f | %.3f |',fs[i],a$original_SR[i],a$managed_SR[i],b$alpha_ann_pct[i],c$original_SR[i],c$combo_SR[i]))
  result<-c(result,'','All values are calculated from the preserved raw archives. Published benchmarks and gaps are in results/tables; exact test statistics, p-values and intervals are in results/inference.',
    '', 'The historical period is August 1926-December 2016. Real-time evaluation is August 1936-December 2016. The preliminary extension calibrates on July 1963-December 2018 and evaluates January 2019-December 2025.',
    '', 'Historical inference follows the paper\'s JK/Memmel Sharpe and DGU CER formulas, with White HC0 alpha inference. The extension bootstrap is separate. Selected results are close to, but not numerically identical to, the publication.')
  writeLines(result,'reports/RESULTS.md')
}
