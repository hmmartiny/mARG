import argparse
import datetime
import numpy as np
import re

from ENA_fetcher import ENAfetcher
from ena_report import reporter
from funcs import query_db

__doc__ = """
This program queries ENA for data that remains to be downloaded by looking at what files have been published since a specific date.
Then the new metadata is retrieved and inserted into the correct database (i.e. AvA), 
as well as producing a file that contains ascp commands for downloading files with the new reads to a given destination.
"""

__author__ = """Hannah-Marie Martiny (hmmartiny)"""

def parse_args():
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    out_args = parser.add_argument_group('Script output arguments')
    out_args.add_argument(
        '--out_file',
        type=str,
        default='runs.json',
        help='Write runs to download to a JSON file.',
        dest='json_file'
    )
    out_args.add_argument(
        '--build_report',
        action='store_true',
        help='If given, build a report with statistics of what was matched with this query.',
        dest='build_report'
    )

    ena_args = parser.add_argument_group('Arguments for retrieving and filtering ENA metadata')
    ena_args.add_argument(
        '-d','--date',
        type=str,
        help='Retrieve all data uploaded from DATE and on until today. Format: YYYY-MM-DD',
        default='2010-01-01',
        dest='low_date'
    ),
    ena_args.add_argument(
        '-td', '--top-date',
        type=str,
        help='Retrieve all data uploaded up to DATE. Format YYYY-MM-DD',
        default=datetime.datetime.now().strftime('%Y-%m-%d'),
        dest='top_date'
    )
    ena_args.add_argument(
        '--min_reads',
        type=int,
        default=1e5,
        help='Minimum number of raw reads required for the run_accession to be downloaded.',
        dest='min_reads'
    )

    ena_args.add_argument(
        '--library_source',
        type=str,
        default='METAGENOMIC',
        help='Library source (see https://ena-docs.readthedocs.io/en/latest/submit/reads/webin-cli.html#permitted-values-for-library-strategy).',
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
        help='Library strategy (see https://ena-docs.readthedocs.io/en/latest/submit/reads/webin-cli.html#permitted-values-for-library-strategy).',
        dest='library_strategy',
    )
    ena_args.add_argument(
        '--library_selection',
        type=str,
        default='RANDOM',
        help='Library selection (see https://ena-docs.readthedocs.io/en/latest/submit/reads/webin-cli.html#permitted-values-for-library-strategy).',
        dest='library_selection'
    )

    sql_args = parser.add_argument_group('Arguments for inserting and updating mysql database')
    sql_args.add_argument(
        '--no-update',
        action='store_false',
        help='Default is to update mysql database. If flag is given, do not update.',
        dest='update_db'
    )
    sql_args.add_argument(
        '--no-silva-check',
        action='store_false',
        help='If given, do not check whether run_accession already has been mapped against Silva db',
        dest='silva_check'
    )

    return parser.parse_args()

if __name__ == "__main__":
    args = parse_args()

    # Build url and fetch matches from ENA
    ena = ENAfetcher()

    print("# Retrieving metadata #")
    print("Pulling read_run metadata...", end='\r')
    run_records = ena.get_readrun(
        date=args.low_date, top_date=args.top_date, 
        min_reads=args.min_reads, 
        library_source=args.library_source, 
        library_strategy=args.library_strategy, 
        library_selection=args.library_selection,
    )
    print("Pulling read_run metadata... Done")
    # TODO: Implement read count filtering to differentiate between sequencing platforms and not only on counts
    # That way we should be able to include long read data

    # remove runs with zero reads
    run_records = run_records.query("read_count > 0")

    # convert library_layout for long-read so pipeline can handle it
    run_records.loc[run_records['instrument_platform'].isin(['OXFORD_NANOPORE', 'PACBIO_SMRT']), 'library_layout'] = 'LONG_READ'


    # get sample metadata
    print("Pulling samples metadata...", end='\r')
    sample_records = ena.get_sampledata(
        sample_accessions=run_records['sample_accession'].unique().tolist(),
        date=args.low_date, top_date=args.top_date
    )
    print("Pulling samples metadata... Done\n")

    print("Pulling assembly data...", end='\r')
    assembly_records = ena.get_assemblydata(sample_accessions=run_records['sample_accession'].unique().tolist())
    print("Pulling assembly data... Done")

    records = run_records.merge(sample_records, how='left', on=['sample_accession', 'host_tax_id',], suffixes=['_run', '_sample'])

     # remove runs that has negative control in sample title or in alias
    p_neg = re.compile(r'(((n|N)egative)?(_|\s)?((c|C)ontrol)?)*')


    records.to_hdf('matched_records_metadata.h5', key='records')
    assembly_records.to_csv('matched_records_metadata.h5', key='assembly')

    records['run_seed_extender']  = True
    if assembly_records is not None:
        records['run_seed_extender'] = ~(records['sample_accession'].isin(assembly_records['sample_accession']).astype('bool'))

    records['run_kma_silva'] = True
    if args.silva_check:
        try:
            silva_runs = query_db(
                "use AvA; select run_accession, run_accession in (SELECT DISTINCT(run_accession) from Bac_public) as silva_run from Meta_public where run_accession in ({})".format(
                    ",".join([f"\'{r}\'" for r in records['run_accession'].tolist()])
                ),
                return_df=True
            )
        
            records.loc[
                records['run_accession'].isin(silva_runs.query("silva_run == 1")['run_accession']), 
                'run_kma_silva'
            ] = False
        except:
            pass

    # to json for pipeline
    runs = records[['run_accession', 'library_layout', 'run_seed_extender', 'run_kma_silva']].rename(columns={'library_layout': 'type'}).copy().set_index('run_accession')
    runs.to_json(args.json_file, orient='index')

    # print(sample_records.head().T)

    # Build report
    if args.build_report:
        ENAreporter = reporter(metadata=records.copy())
        ENAreporter.build(min_read_count=args.min_reads)
