Data Loading (R)
================

<small>Tutorial written by: Hannah-Marie Martiny
(<hanmar@food.dtu.dk>)<br> Last updated: 20-12-2021</small>

In this tutorial, a brief overview of how to load the data in the
different formats are given: MySQL, TSV and HDF.

<em>NOTE: The various settings that are sensitive are stored in a
config.json file, but just change the settings to what fit your own
setup.</em>

``` r
library('rjson')
config <- fromJSON(file="../config.json")

database <- config$database # name of database
host <- config$host # host address of MySQL server
port <- config$port # port of MySQL server
user <- config$user # user name
passwd <- config$password # password for user 
dataDir <- config$datadir # directory where data files are stored
```

## MySQL

### Loading MySQL dumps

For each of the dump files (.sql), load them with the command
`mysql db_name < dump-file.sql`. `db_name` is the name of database to
contain the tables, and the `dump-file.sql` is the file containing the
table structure and data.

We have written a short bash script [`loader.sh`](loader.sh) for this,
where we give the path to the directory containing dump files
(`-d $datadir`) and the name of the MySQL database (`-n $database`):

``` bash
loader.sh -d $datadir -n $database
```

### Reading data from a MySQL database

We can use the [RMySQL](https://cran.r-project.org/web/packages/RMySQL/)
package to connect to the MySQL database.

``` r
# install.packages("RMySQL")
library(RMySQL)
```

    ## Loading required package: DBI

``` r
mydb = dbConnect(MySQL(), user=user, password=passwd, host=host, port=as.integer(port), dbname=database)
rs = dbSendQuery(mydb, "select * from metadata")
data = fetch(rs, n=5)
data
```

    ##   run_accession sample_accession project_accession country location continent
    ## 1     DRR000836     SAMD00002573        PRJDA61421    <NA>     <NA>      <NA>
    ## 2     DRR000980     SAMD00010106         PRJDB2325    <NA>     <NA>      <NA>
    ## 3     DRR000981     SAMD00010105         PRJDB2325    <NA>     <NA>      <NA>
    ## 4     DRR001376     SAMD00006238        PRJDA72837    <NA>     <NA>      <NA>
    ## 5     DRR001455     SAMD00015677         PRJDB2729    <NA>     <NA>      <NA>
    ##   collection_date  tax_id                   host host_tax_id
    ## 1            <NA>  939928 rhizosphere metagenome          NA
    ## 2            <NA> 1006967       shoot metagenome          NA
    ## 3            <NA> 1006967       shoot metagenome          NA
    ## 4            <NA>    9606           Homo sapiens        9606
    ## 5            <NA>  410658        soil metagenome          NA
    ##   instrument_platform             instrument_model library_layout raw_reads
    ## 1               LS454          454 GS FLX Titanium         SINGLE   1268608
    ## 2               LS454                   454 GS FLX         SINGLE   1207522
    ## 3               LS454                   454 GS FLX         SINGLE    802422
    ## 4            ILLUMINA Illumina Genome Analyzer IIx         SINGLE    336278
    ## 5            ILLUMINA Illumina Genome Analyzer IIx         PAIRED  21452087
    ##   trimmed_reads  raw_bases trimmed_bases trimmed_fragments
    ## 1       1247751  641025182     411961081           1247751
    ## 2       1190673  596228115     416966759           1190673
    ## 3        792888  424054817     303648013            792888
    ## 4        256975   42034750      26464638            256975
    ## 5       5146184 3217813050     336410211           7991359

## Tab-separated files (TSV)

It is fairly straightforward to read the .tsv files in R with either
native functions or for example readr.

``` r
# with native read.csv
data <- read.csv(file.path(dataDir, 'metadata.tsv'), sep='\t')
head(data)
```

    ##   run_accession sample_accession project_accession country location continent
    ## 1     DRR000836     SAMD00002573        PRJDA61421    NULL     NULL      NULL
    ## 2     DRR000980     SAMD00010106         PRJDB2325    NULL     NULL      NULL
    ## 3     DRR000981     SAMD00010105         PRJDB2325    NULL     NULL      NULL
    ## 4     DRR001376     SAMD00006238        PRJDA72837    NULL     NULL      NULL
    ## 5     DRR001455     SAMD00015677         PRJDB2729    NULL     NULL      NULL
    ## 6     DRR001456     SAMD00015673         PRJDB2729    NULL     NULL      NULL
    ##   collection_date  tax_id                   host host_tax_id
    ## 1            NULL  939928 rhizosphere metagenome        NULL
    ## 2            NULL 1006967       shoot metagenome        NULL
    ## 3            NULL 1006967       shoot metagenome        NULL
    ## 4            NULL    9606           Homo sapiens        9606
    ## 5            NULL  410658        soil metagenome        NULL
    ## 6            NULL  410658        soil metagenome        NULL
    ##   instrument_platform             instrument_model library_layout raw_reads
    ## 1               LS454          454 GS FLX Titanium         SINGLE   1268608
    ## 2               LS454                   454 GS FLX         SINGLE   1207522
    ## 3               LS454                   454 GS FLX         SINGLE    802422
    ## 4            ILLUMINA Illumina Genome Analyzer IIx         SINGLE    336278
    ## 5            ILLUMINA Illumina Genome Analyzer IIx         PAIRED  21452087
    ## 6            ILLUMINA Illumina Genome Analyzer IIx         PAIRED  12911269
    ##   trimmed_reads  raw_bases trimmed_bases trimmed_fragments
    ## 1       1247751  641025182     411961081           1247751
    ## 2       1190673  596228115     416966759           1190673
    ## 3        792888  424054817     303648013            792888
    ## 4        256975   42034750      26464638            256975
    ## 5       5146184 3217813050     336410211           7991359
    ## 6       3824532 1936690350     245042781           6066377

``` r
# with readr
# install.packages("readr")
data <- readr::read_tsv(file.path(dataDir, 'metadata.tsv'))
```

    ## Rows: 20 Columns: 18

    ## ── Column specification ────────────────────────────────────────────────────────
    ## Delimiter: "\t"
    ## chr (12): run_accession, sample_accession, project_accession, country, locat...
    ## dbl  (6): tax_id, raw_reads, trimmed_reads, raw_bases, trimmed_bases, trimme...

    ## 
    ## ℹ Use `spec()` to retrieve the full column specification for this data.
    ## ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.

``` r
head(data)
```

    ## # A tibble: 6 × 18
    ##   run_accession sample_accession project_accession country location continent
    ##   <chr>         <chr>            <chr>             <chr>   <chr>    <chr>    
    ## 1 DRR000836     SAMD00002573     PRJDA61421        NULL    NULL     NULL     
    ## 2 DRR000980     SAMD00010106     PRJDB2325         NULL    NULL     NULL     
    ## 3 DRR000981     SAMD00010105     PRJDB2325         NULL    NULL     NULL     
    ## 4 DRR001376     SAMD00006238     PRJDA72837        NULL    NULL     NULL     
    ## 5 DRR001455     SAMD00015677     PRJDB2729         NULL    NULL     NULL     
    ## 6 DRR001456     SAMD00015673     PRJDB2729         NULL    NULL     NULL     
    ## # … with 12 more variables: collection_date <chr>, tax_id <dbl>, host <chr>,
    ## #   host_tax_id <chr>, instrument_platform <chr>, instrument_model <chr>,
    ## #   library_layout <chr>, raw_reads <dbl>, trimmed_reads <dbl>,
    ## #   raw_bases <dbl>, trimmed_bases <dbl>, trimmed_fragments <dbl>

## HDF5 files

There are no straight forward ways in R to load the HDF5 file types,
although there are several libraries that claim to do it, like
[hdf5r](https://hhoeflin.github.io/hdf5r/) and
[rhdf5](https://www.bioconductor.org/packages/devel/bioc/vignettes/rhdf5/inst/doc/rhdf5.html).
Let us know if you can get it to work!
