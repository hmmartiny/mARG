Scripts for interacting with ENA and our internal sql database.


### Query ENA for metagenomic datasets with `ENA_query.py`
```
$ python ENA_query.py -h
usage: ENA_query.py [-h] [--out_file JSON_FILE] [--build_report] [-d LOW_DATE] [-td TOP_DATE] [--min_reads MIN_READS]
                    [--library_source {GENOMIC,GENOMIC SINGLE CELL,TRANSCRIPTOMIC,TRANSCRIPTOMIC SINGLE CELL,METAGENOMIC,METATRANSCRIPTOMIC,SYNTHETIC,VIRAL RNA,OTHER}] [--library_strategy LIBRARY_STRATEGY]
                    [--library_selection LIBRARY_SELECTION] [--no-update]

optional arguments:
  -h, --help            show this help message and exit

Script output arguments:
  --out_file JSON_FILE  Write runs to download to a JSON file. (default: runs.json)
  --build_report        If given, build a report with statistics of what was matched with this query. (default: False)

Arguments for retrieving and filtering ENA metadata:
  -d LOW_DATE, --date LOW_DATE
                        Retrieve all data uploaded from DATE and on until today. Format: YYYY-MM-DD (default: 2010-01-01)
  -td TOP_DATE, --top-date TOP_DATE
                        Retrieve all data uploaded up to DATE. Format YYYY-MM-DD (default: 2023-02-22)
  --min_reads MIN_READS
                        Minimum number of raw reads required for the run_accession to be downloaded. (default: 100000.0)
  --library_source {GENOMIC,GENOMIC SINGLE CELL,TRANSCRIPTOMIC,TRANSCRIPTOMIC SINGLE CELL,METAGENOMIC,METATRANSCRIPTOMIC,SYNTHETIC,VIRAL RNA,OTHER}
                        Library source (see https://ena-docs.readthedocs.io/en/latest/submit/reads/webin-cli.html#permitted-values-for-library-strategy). (default: METAGENOMIC)
  --library_strategy LIBRARY_STRATEGY
                        Library strategy (see https://ena-docs.readthedocs.io/en/latest/submit/reads/webin-cli.html#permitted-values-for-library-strategy). (default: WGS)
  --library_selection LIBRARY_SELECTION
                        Library selection (see https://ena-docs.readthedocs.io/en/latest/submit/reads/webin-cli.html#permitted-values-for-library-strategy). (default: RANDOM)

Arguments for inserting and updating mysql database:
  --no-update           Default is to update mysql database. If flag is given, do not update. (default: True)
```

#### Example
Retrieve metagenomic datasets uploaded between 2023-01-01 and 2023-01-10
```
$ python ENA_query.py -d 2023-01-01 -td 2023-01-10 
```