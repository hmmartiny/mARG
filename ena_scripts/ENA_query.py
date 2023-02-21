import argparse
import datetime
import numpy as np

from ENA_fetcher import ENAfetcher
from ena_report import reporter

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

    print(run_records.head().T)

    # TODO: Implement read count filtering to differentiate between sequencing platforms and not only on counts
    # That way we should be able to include long read data

    # remove runs with zero reads
    run_records = run_records.query("read_count > 0")

    # convert library_layout for long-read so pipeline can handle it
    run_records.loc[run_records['instrument_platform'].isin(['OXFORD_NANOPORE', 'PACBIO_SMRT']), 'library_layout'] = 'LONG_READ'

    # to json for pipeline
    # runs = run_records[['run_accession', 'library_layout']].rename(columns={'library_layout': 'type'}).copy().set_index('run_accession')
    # runs.to_json(args.json_file, orient='index')

    # get sample metadata
    print("Pulling samples metadata...", end='\r')
    sample_records = ena.get_sampledata(
        sample_accessions=run_records['sample_accession'].unique().tolist(),
        date=args.low_date, top_date=args.top_date
    )
    print("Pulling samples metadata... Done\n")

    records = run_records.merge(sample_records, how='left', on=['sample_accession', 'host_tax_id',], suffixes=['_run', '_sample'])
    records.to_csv('matched_records_metadata.csv')

    # print(sample_records.head().T)

    # Build report
    if args.build_report:
        ENAreporter = reporter(metadata=run_records.copy())
        ENAreporter.build(min_read_count=args.min_reads)
