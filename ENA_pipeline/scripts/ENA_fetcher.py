#!/usr/bin/env python3

import argparse
import requests
import pandas as pd
import sys
import os
import datetime
import subprocess
import numpy as np

from funcs import query_db

__doc__ = """
This program queries ENA for data that remains to be downloaded by looking at what files have been published since a specific date.
Then the new metadata is retrieved and inserted into the correct database (i.e. AvA), 
as well as producing a file that contains ascp commands for downloading files with the new reads to a given destination.
"""

ext_doc = """# Detailed description #
First, the query to retrieve metadata from ENA is built and then executed. The query contains filters for which library source, library strategy and library selection used and what is the earliest ENA publication date to match. 
By default, library source is metagenomic, library strategy is whole genome sequencing (WGS) and library selection is random (no selection or random selection). A date should always be given by the user.

Next, the matched metadata is filtered for a minim number of reads required for a file to be downloaded. 
By default, at least 100,000 reads should be available for a given sequencing run.

Finally, rows that match extra filters will be removed from the retrieved metadata. 
This can be optional, but by default the rows that match these criteria are removed: 
 * runs that are not from USA and are taken before 2015. 
 * runs that are from human host and are taken before 2015.

# Output description #
The output written to the standard output gives both the result from filtering the matches as well as the number of data that matches these criteria and are already downloaded. 
There is one file produced by the script, which contains the ascp commands needed for retrieving the sequencing matched run files. By default, the MySQL database is updated with the new metadata.
"""

title = "## Retrieving ENA data ##"

def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)

    out_args = parser.add_argument_group('Script output arguments')
    out_args.add_argument(
        '--out_file',
        type=str,
        default='ena_ascp_download.sh',
        help='Write ASCP commands to a file. Default: ena_ascp_download.sh',
        dest='cmd_file'
    )
    out_args.add_argument(
        '-b', '--base',
        type=str,
        required=True,
        help='Base destination to store files with raw reads in.',
        dest='base'
    )
    out_args.add_argument(
        '--batch_size',
        type=int,
        default=10,
        help="Size of batches in terabytes, default: 10",
        dest='batch_size'
    )

    ena_args = parser.add_argument_group('Arguments for retrieving and filtering ENA metadata')
    ena_args.add_argument(
        '-d','--date',
        type=str,
        help='Retrieve all data uploaded from DATE and on until today. Format: YYYY-MM-DD. Default: 2019-05-06',
        default='2019-05-06',
        dest='low_date'
    ),
    ena_args.add_argument(
        '-td', '--top-date',
        type=str,
        help='Retrieve all data uploaded up to DATE. Format YYYY-MM-DD. Default: today.',
        default=datetime.datetime.now().strftime('%Y-%m-%d'),
        dest='top_date'
    )
    ena_args.add_argument(
        '--min_reads',
        type=int,
        default=1e5,
        help='Minimum number of raw reads required for the run_accession to be downloaded. Default: 100000.',
        dest='min_reads'
    )
    ena_args.add_argument(
        '-f', '--filters',
        type=str,
        default="(country != 'USA' and collection_date_year < 2015) or (host == 'Homo sapiens' and collection_date_year < 2015)",
        help='Additional filters used to drop rows. It works by matching the filter and then removing matches. Example: country != "USA" and collection_date < 2015 will remove matching rows. Written as: (country != "USA" and collection_date_year < 2015) or (host == "Homo sapiens" and collection_date_year < 2015)',
        dest='filters'
    )
    ena_args.add_argument(
        '--library_source',
        type=str,
        default='METAGENOMIC',
        help='Library source (see https://ena-docs.readthedocs.io/en/latest/submit/reads/webin-cli.html#permitted-values-for-library-strategy), default: METAGENOMIC',
        dest='library_source',
        choices=[
            'GENOMIC', 'GENOMIC SINGLE CELL', 'TRANSCRIPTOMIC', 
            'TRANSCRIPTOMIC SINGLE CELL', 'METAGENOMIC', 'METATRANSCRIPTOMIC', 
            'SYNTHETIC', 'VIRAL RNA', 'OTHER'
        ]
    )
    ena_args.add_argument(
        '--library_strategy',
        type=str,
        default='WGS',
        help='Library strategy (see https://ena-docs.readthedocs.io/en/latest/submit/reads/webin-cli.html#permitted-values-for-library-strategy), default: WGS',
        dest='library_strategy',
    )
    ena_args.add_argument(
        '--library_selection',
        type=str,
        default='RANDOM',
        help='Library selection (see https://ena-docs.readthedocs.io/en/latest/submit/reads/webin-cli.html#permitted-values-for-library-strategy), default: RANDOM',
        dest='library_selection'
    )


    sql_args = parser.add_argument_group('MySQL arguments for connecting to the db')
    sql_args.add_argument(
        '-host',
        type=str,
        dest='host',
        help='MySQL host address',
        required=False
    )
    sql_args.add_argument(
        '-db',
        type=str,
        dest='db',
        help='MySQL database name.',
        required=False
    )
    # sql_args.add_argument(
    #     '-port',
    #     default=30306,
    #     type=int,
    #     dest='port',
    #     help='MySQL port number. Default: 30306'
    # )
    sql_args.add_argument(
        '-user',
        type=str,
        help='MySQL user',
        dest='user',
        required=False
    )
    sql_args.add_argument(
        '-pw',
        type=str,
        help='Password for MySQL user',
        dest='password',
        required=False
    )
    sql_args.add_argument(
        '--no-update',
        action='store_false',
        help='Do not update the MySQL db with the new data',
        dest='update'
    )
    sql_args.add_argument(
        '--no-check_db',
        action='store_false',
        help='Cross check with the MySQL db whether or not run_accessions have already been downloaded.',
        dest='check_db'
    )

    return parser.parse_args()


samples_columns =[
    'sample_accession', 'location', 'country', 'collection_date',
    'description', 'sampling_campaign', 'host', 'host_tax_id', 
    'host_status', 'host_sex', 'host_phenotype',
    'investigation_type', 'sample_title'
        ]

run_results_columns = [
    'run_accession', 'fastq_bytes', 'fastq_ftp', 'fastq_aspera', 'fastq_md5',
    'nominal_length', 'read_count', 'base_count', 'center_name', 'tax_id',
    'sample_accession', 'sample_alias', 'host_tax_id', 'instrument_platform',
    'instrument_model', 'library_source', 'library_strategy', 'library_selection', 
    'library_layout', 'study_accession', 'first_public','last_updated'
]

env_samples_columns = [
    'sample_accession', 'environment_biome', 'environment_feature',
    'environment_material', 'environmental_package', 'host_tax_id'
]

study_results_columns = ['study_accession', 'study_title', 'description']


class ENAfetcher:

    def __init__(self, url='https://www.ebi.ac.uk/ena/portal/api/search?'):

        self.base_url = url

        self.comma = "%2C%20"
        self.nleg = "%3E%3D" # >=
        self.leg = "%3C%3D" # <=


        self.readrun_fields = [
            'run_accession', 'fastq_bytes', 'fastq_ftp', 'fastq_aspera',
            'fastq_md5', 'nominal_length', 'read_count', 'base_count',
            'center_name','tax_id','sample_accession','sample_alias',
            'host_tax_id','instrument_platform','instrument_model',
            'library_source','library_strategy','library_selection',
            'library_layout','study_accession','first_public','last_updated', 'study_title', 'description'
        ]
        self.sample_fields = [
            'sample_accession', 'location', 'country',
            'collection_date', 'description', 'sampling_campaign',
            'host', 'host_tax_id', 'host_status',
            'host_sex', 'host_phenotype', 'investigation_type', 'sample_title'
        ]
        self.envsample_fields = [
            'sample_accession', 'environment_biome',
            'environment_feature', 'environment_material',
            'environmental_package', 'host_tax_id'
        ] 

        self.sample_fields_ext = self.sample_fields + self.envsample_fields

    def build_url(self, result, fields, query=None, download_format='json', dataPortal='ena', verbose=False):
        """Construct URL to interact with ENA's api and fetch results

        Parameters
        ----------
        result : str
            The data set to search against (e.g. read_run or samples)
        fields : list
            A list of fields to be returned in the result.
        query : str, optional
            A set of search conditions, by default None
        downloadformat : str, optional
            What format the results should be returned as. Must be either json or TSV, by default 'json'
        dataPortal : str, optional
            The data portal ID. Can be either ena, faang, metagenome or pathogen, by default 'ena'
        verbose : bool, optional
            If true, print the url to stdout. By default False
        Returns
        -------
        df : pd.DataFrame or None
            If url was succssfull, return the data as pd.DataFrame. Else it returns None.
        """

        url = self.base_url
        url += 'dataPortal=' + dataPortal
        url += '&download=true'
        url += '&format=' + download_format
        url += '&fields=' + fields
        url += '&limit=0'
        url += '&result=' + result

        if query is not None:
            url += query

        if verbose:
            print(url)
        
        data = self.url_request(url)
        return data

    def url_request(self, url):

        r = requests.get(url)
        if r:
            out = r.json()
            df = pd.DataFrame(out)
            df.replace('', np.nan, inplace=True)
            return df

        else:
            print(r.status_code)
            print(f"Query failed ({r.text} from url {url}).")
            return None
        

    def get_readrun(self, date=None, top_date=None, min_reads=1e5, check_db=None, library_source='METAGENOMIC', library_strategy='WGS', library_selection='RANDOM'):
        """Retrieve records containg run_accession information published from DATE and onward until current date.

        Parameters
        ----------
        date : str
            Date to retrieve data from. Format: YYYY-MM-DD
        top_date : str
            Date to retrieve date up until. Format YYYY-MM-DD
        min_reads : int, optional
            Minimum number of reads required to be in a file for it to be downloaded, by default: 1e5
        check_db : list
            Cross check queried run_accessions with those already in the MySQL db
        library_source: str
            Which library source (see ENA API documentation), by default: metagenomic
        library_strategy: str
            Which library strategy (see ENA API documentation), by default: wgs
        library_selection: str
            Which library selection (see ENA API documentation), by default: random

        Returns
        -------
        pd.DataFrame
            downloaded records in a pd.DataFrame
        """

        query=f"&query=library_source%3D%22{library_source}%22%20AND%20library_strategy%3D%22{library_strategy}%22%20AND%20library_selection%3D%22{library_selection}" 

        self.date_query = ''
        if date is not None:
            #self.date_query += 'first_public' + self.nleg + date
            self.date_query += 'first_public>=' + date
        
        # filter on maximum date
        if top_date is not None:
            s = 'first_public<='  + top_date
            if len(self.date_query) > 0:
                self.date_query += '%20AND%20' + s
            else:
                self.date_query += s

        query+= '%22%20AND%20' + self.date_query
        df = self.build_url(result='read_run', fields=self.comma.join(self.readrun_fields), query=query)

        if df is None:
            return pd.DataFrame(), '', 0
        
        df['read_count'] = pd.to_numeric(df['read_count'])

        n = df.shape[0]
        filtering_str = f" * Matched {n} runs in ENA initially." 

        # filter on minimum number of reads and that fastq_ftp should not be empty
        df = df.loc[
            ~ (df.fastq_ftp.isna() ) & 
            (df.read_count >= min_reads )
        ]

        filtering_str += f'\n * Filtering for minimum number of reads (>= {min_reads}): removed {n-df.shape[0]}, {df.shape[0]} runs left.'
        n = df.shape[0]

        # cross check
        if check_db is not None:
            df = df.loc[ ~ (df.run_accession.isin(check_db))]

            filtering_str += f'\n * Filtering runs that are already downloaded: removed {n-df.shape[0]}, {df.shape[0]} runs left.'
            n = df.shape[0]

        return df, filtering_str, n

    def get_loop(self, ids, result, fields, accession, k=1):

        outs = [] 
        i = 0
        N = len(ids)
        while i < N:
            query = f'&{accession}=' + ','.join(ids[i:i+k])
            out = self.build_url(result=result, fields=fields, query=query)
            if out is not None:
                outs.append(out)

            i += k
        
        return pd.concat(outs)
        
    def get_sampledata(self, sample_accessions, k=1):
        """Retrieve sample metadata for all samples matching the list of sample_accessions from ENA.

        Parameters
        ----------
        sample_accessions : list
            List of sample_accessions to match.

        Returns
        -------
        pd.DataFrame
            downloaded records in a pd.DataFrame
        """
        query = None
        if hasattr(self, 'date_query'):
            query = '&query=' + self.date_query

        df = self.build_url(result='sample', fields=self.comma.join(self.sample_fields_ext), query=query)
        df = df.loc[df.sample_accession.isin(sample_accessions)]
        #df = self.get_loop(ids=sample_accessions, result='sample', fields=self.comma.join(self.sample_fields_ext), k=k, accession='sample_accession')
        return df[self.sample_fields], df[self.envsample_fields]

def check_runs(db_args):
    """Check the MySQL database which run_accessions have been downloaded already.

    Parameters
    ----------
    db_args : str
        Dict  with args for connecting to the MySQL db

    Returns
    -------
    list
        Matched run_accessions
    """
    sql_select = "SELECT run_accession FROM run_overview WHERE downloaded=1"
    out = query_db(cmd=sql_select, return_df=True, **db_args)
    out = out['run_accession'].dropna().values.tolist()

    return out

def filter_db(db_args, date, min_reads, additional_filters, library_source='METAGENOMIC', library_strategy='WGS', library_selection='RANDOM'):

    sql_select = "SELECT m.* from metadata as m inner join run_overview as ro on m.run_accession=ro.run_accession where downloaded = 1"
    sql_select += f" and library_source='{library_source}' and library_strategy='{library_strategy}' and library_selection='{library_selection}' "
    sql_select += f" and raw_reads >= {min_reads} and first_public >= {date}" 
    df = query_db(sql_select, return_df=True, **db_args)
    df['collection_date_year'] = pd.to_datetime(df['collection_date'], errors='coerce').dt.year

    to_drop = df.query(additional_filters)
    df = df.loc[~(df.run_accession.isin(to_drop.run_accession))]

    n_runs, n_samples, n_projects = df.shape[0], df.sample_accession.nunique(), df.project_accession.nunique()
    filtering_str = f'Data already downloaded:\n * All filters matches {n_runs} runs from {n_samples} samples from {n_projects} projects.'

    print(filtering_str)

def check_metadata(sample_accessions, db_args):

    query = "select distinct(sample_accession) as sample_accession from run_results"
    samples = query_db(query, return_df=True, **db_args)
    already_downloaded = set(samples['sample_accession'].values)
    not_downloaded = set(sample_accessions) - already_downloaded

    return list(not_downloaded)

def aspera_file(run_records, dest, outfile, batch_size=1):

    openssh = '/services/tools/ascp/3.9.6/cli/etc/asperaweb_id_dsa.openssh'
    aspera_cmd = "ascp -d -QT -k 1 -l 300m -P33001 -i {openssh} era-fasp@{path} {out_file}"
    
    # batch = 0
    # batchsize=0

    b = 0
    current_batchSize = 0
    out = open(outfile.replace('.sh', f'_{b}.sh'), 'w')
    for _, record in run_records.iterrows():
        fastq_aspera = record['fastq_aspera'].split(';')
        project = record['study_accession']
        fastq_bytes = record['fastq_bytes'].split(';')

        file_dest = os.path.join(dest, project, 'raw')

        for path, fastq_byte in zip(fastq_aspera, fastq_bytes):
            current_batchSize += ( float(fastq_byte) * 10**(-12))
            
            out_file = os.path.join(file_dest, path.split('/')[-1])
            cmd = aspera_cmd.format(
                openssh=openssh,
                path=path,
                out_file=out_file
            )

            print(cmd, file=out)
        
        if current_batchSize >= batch_size: # make new batch if exceeding threshold
            out.close()
            b += 1
            current_batchSize = 0
            out = open(outfile.replace('.sh', f'_{b}.sh'), 'w')
    
    out.close()

def to_sql(df, table, db_args, temp_name='temp.csv'):

    temp_name=os.path.realpath(temp_name)

    df.to_csv(temp_name, index=None, header=None)

    sql_insert = rf"LOAD DATA LOCAL INFILE '{temp_name}' REPLACE INTO table {table} FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n'"

    # cmd = r'mysql --host {host} --database {db} --user {user} --password={passwd} -e "{sql}"'.format(
    #     sql=sql_insert,**db_args
    # ) 
    # subprocess.run(cmd, shell=True, stderr=subprocess.PIPE)

    query_db(cmd=sql_insert, return_df=False, **db_args)

    os.remove(temp_name)

def prettify_args():
    args = sys.argv
    try:
        pw_idx = args.index('-pw')
        args[pw_idx+1] = "$PASSWORD"
    except ValueError:
        pass

    print("# python", " ".join(args))
    print()

if __name__ == "__main__":
    args = parse_args()
    prettify_args()

    print(title)
    print(__doc__)
    print(ext_doc)

    # arguments for connecting to MySQL db
    db_args = {
        "passwd": args.password, 
        "host": args.host, 
        "db": args.db, 
        "user": args.user}

    print("## Output ##")
    print("# Filters for API query #")
    print(f" * library_source = '{args.library_source}'")
    print(f" * library_strategy = '{args.library_strategy}'")
    print(f" * library_selection = '{args.library_selection}'")
    print(" * number of reads >= ", args.min_reads)
    print(f" * {args.top_date} >= first_public >= {args.low_date}")
    print()
    if len(args.filters) > 0:
        print("Filters applied to remove matches from results:\n", args.filters)
    print()

    downloaded_runs=None
    if args.check_db:
        downloaded_runs = check_runs(db_args)
    
    ena = ENAfetcher()
    
    print("# Retrieving metadata #")
    print("Pulling read_run metadata...", end='\r')
    run_records, filtering_str, n = ena.get_readrun(date=args.low_date, top_date=args.top_date, min_reads=args.min_reads, check_db=downloaded_runs, library_source=args.library_source, library_strategy=args.library_strategy, library_selection=args.library_selection)
    print("Pulling read_run metadata... Done")

    if run_records.shape[0] == 0:
        print("No records found. Exiting..")
        sys.exit()

    sample_accessions = check_metadata(run_records.sample_accession.unique().tolist(), db_args)
    print("Pulling samples metadata...", end='\r')
    sample_records, env_records = ena.get_sampledata(sample_accessions=sample_accessions, k=1)
    print("Pulling samples metadata... Done\n")

    # filters
    n_samples_org = sample_records.shape[0]
    sample_records['collection_date_year'] = pd.to_datetime(sample_records['collection_date']).dt.year
    if len(args.filters) > 0:
        to_drop = sample_records.query(args.filters)
        run_records = run_records.loc[ ~(run_records.sample_accession.isin(to_drop.sample_accession))]
        sample_records = sample_records.loc[ ~(sample_records.sample_accession.isin(to_drop.sample_accession))]
        env_records = env_records.loc[ ~(env_records.sample_accession.isin(to_drop.sample_accession))]
        filtering_str += f'\n * Applying filters {args.filters}: removed {n-run_records.shape[0]}, {run_records.shape[0]} runs left.'

    print("# What happened during filtering? #")
    print(filtering_str)
    print()

    total_bytes = [int(y) for x in run_records['fastq_bytes'].apply(lambda x: x.split(';')).values for y in x if len(y) > 0]

    print("# Results #")
    filter_db(db_args, args.low_date, args.min_reads, args.filters)
    print()
    
    print("Data to be downloaded:")
    print(" * Number of run_accessions:", run_records.shape[0])
    print(" * Number of samples:", sample_records.sample_accession.nunique())
    print(" * Number of projects: {}".format(run_records.study_accession.nunique()))
    print(f" * Files to download: {len(total_bytes)}")
    print(f" * Space required: {sum(total_bytes) * 10**(-12):.3f} terabytes")
    print()

    # insert metadata into mysql db
    if args.update:
        to_sql(sample_records[samples_columns], table='samples', db_args=db_args)
        to_sql(env_records[env_samples_columns], table='env_samples', db_args=db_args)
        to_sql(run_records[study_results_columns], table='study_results', db_args=db_args)
        to_sql(run_records[run_results_columns], table='run_results', db_args=db_args)

        print(f"MySQL database updated with retrieved metadata.")
        print()
    
    aspera_file(run_records, dest=args.base, outfile=args.cmd_file, batch_size=args.batch_size)
    print(f"Run '{args.cmd_file.replace('.sh', '*.sh')}' to start downloading runs with Aspera.")

    print("\nDone.")