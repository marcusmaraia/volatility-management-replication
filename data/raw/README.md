# Source-data provenance

Provider: Kenneth R. French Data Library, U.S. Fama-French three factors.

Preserved inputs recovered from the user's earlier local replication folder:

| File | Header vintage | SHA-256 |
| --- | --- | --- |
| F-F_Research_Data_Factors.zip | 202609 CRSP database | b03d39e4bb253dda0f14893db3b78e64b40b8d6549a0fc0fd4111dae84c98618 |
| F-F_Research_Data_Factors_daily.zip | 202609 CRSP database | 96c23b88e651cbfff3740a53f8225e59ee39893371e96385a1d8125ec2cd9c89 |

Official current-download locations (may change vintage):

- [Monthly ZIP](https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_Factors_CSV.zip)
- [Daily ZIP](https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_Factors_daily_CSV.zip)

The preserved ZIP entries carry October 26, 2026 timestamps; the original local download time was not independently recorded. The headers, hashes, and successful reconstruction establish which files reproduce this package, not the paper authors' historical source files. Do not overwrite these archives with new downloads when reproducing this snapshot.

`R/01_prepare_data.R` reads the first contiguous daily/monthly data block, converts percentages to decimals, computes factor-specific monthly squared-return signals, and lags them by one month. The first monthly row has no prior-month variance. The full 1,203-row, 14-column processed dataset was checked against the earlier provided snapshot, with numerical tolerance 1e-12.
