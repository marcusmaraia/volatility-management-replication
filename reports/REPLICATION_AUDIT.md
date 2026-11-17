# Replication audit

## What was checked

1. Read the published JFE paper, especially Eqs. (3)-(4), Table 1/footnote 8, Table 3 Panel A, and Section 4.3.1/Table 5/footnote 19. Checked the selected published benchmark numbers against the tables.
2. Reconstructed the complete processed snapshot from the recovered raw archives, then checked signal timing, sample sizes, volatility matching, HC0, historical test formulas, recursive allocations, and extension costs/calibration.
3. Regenerated the R charts and computed slide tables from the same results; checked the presentation for consistency and fit.

Source: [published paper on coauthor Yan's website](https://www.lehigh.edu/~xuy219/research/COWY.pdf), JFE 138 (2020), 95-117. Author source-code identity and original-vintage data identity are not claimed.

## Fidelity decisions

| Item | Final treatment |
| --- | --- |
| Historical strategy and samples | Paper-aligned inverse-variance signal, one-month lag, full-sample volatility matching, and 1926-2016 sample for the three selected factors. |
| Historical Sharpe inference | Replaced earlier added block-bootstrap labels with the paper's JK/Memmel test. |
| Historical CER inference | Uses the paper's footnote-19 normal approximation. |
| Spanning alpha | White HC0, as specified by the paper; no blanket serial-correlation-robust claim. |
| Real-time exposure | Eqs. (15)-(16) and the main text's absolute total exposure limit. Earlier generic warnings that post-estimation exposure limiting necessarily departs from the paper were too strong. |
| Ex post reference | Fixed ex post combination weights, without applying the real-time clipping rule. |
| Preliminary extension | Separate from published results; calibration corrected to July 1963-December 2018 as proposed. Its block bootstrap remains explicitly exploratory. |

The Table 5 caption says the sum of absolute risky-factor weights is bounded by five, while Section 4.3.1 explicitly says |y_t| <= 5 for the total position in the underlying factor. These constraints are not generally identical. The code follows the latter explicit construction; this ambiguity prevents claiming every author implementation detail is settled.

## Numerical boundaries

The historical point estimates reproduce the earlier uploaded results for direct Sharpe, spanning coefficients, and real-time original/combination returns. The recovered raw archives reproduce all 1,203 processed monthly rows and 14 columns. The data vintage is September 2026, not the authors' original vintage. Published-vs-computed comparison CSVs retain the differences; agreement was not forced by changing inputs or inserting paper estimates.

MKT managed Sharpe is about 0.513 versus published 0.51, and market alpha is about 4.607% versus 4.63%. HML is less close: managed Sharpe about 0.367 versus 0.38 and alpha about 1.753% versus 1.87%. Direct and real-time Sharpe tests still do not reject at 5% for these three factors; market alpha does reject under HC0. The extension's changed calibration affects its scale, costs, drawdowns and some net performance, so older deck numbers must not be mixed with this version.

The tests are asymptotic approximations. The separate extension bootstrap resamples paired generated returns and does not regenerate strategy estimation in each draw. Its percentile interval and centered bootstrap p-value are different approximate summaries. No multiple-comparison adjustment or block-length sensitivity claim is made.
