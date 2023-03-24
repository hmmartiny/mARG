import argparse
import subprocess
import re
import pandas as pd
import tempfile
import csv

def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        '-f',
        type=str,
        required=True,
        nargs='+',
        help='Mapstat file(s) to insert',
        dest='datafiles'

    )

    return parser.parse_args()

def extract_header_info(header):
    p_runid = re.compile(r'((E|D|S)RR[0-9]{6,})')

    kma_version = header[0].split('\t')[-1]
    dbs = header[1].split('\t')[-1]
    if 'pan.fa' == dbs:
        database, database_version = 'panRes', '20230227'
    else:
        database, database_version = header[1].split('\t')[-1].split('_')
    total_readfragmentCount = header[2].split('\t')[-1]
    run_date =  header[3].split('\t')[-1]
    command =  header[4].split('\t')[-1].replace('"', '')

    matches = list(set(p_runid.findall(header[4])))
    runid = matches[0][0]

    return [runid, database, database_version, kma_version, run_date, total_readfragmentCount, command]

def load_mapstat(mapstatfile):
    # load header
    with open(mapstatfile, 'r') as f:
        lines = f.readlines()
        header_content = lines[1:6]
        header_content = [l.strip() for l in header_content]
        del lines

    header = extract_header_info(header_content)
    del header_content

    # load results
    mapstatData = pd.read_csv(mapstatfile, sep='\t', skiprows=6)
    mapstatData.columns = [c.replace('#', '').strip() for c in mapstatData.columns]

    mapstatData[['run_accession', 'db', 'db_version', 'kma_version', 'run_date', 'total_readfragmentCount']] = header[:-1]

    mapstatColumnOrder = [
        'run_accession','db','db_version','kma_version',
        'run_date','total_readfragmentCount','refSequence',
        'readCount','fragmentCount','mapScoreSum','refCoveredPositions',
        'refConsensusSum','bpTotal','depthVariance','nucHighDepthVariance',
        'depthMax','snpSum','insertSum','deletionSum','readCountAln','fragmentCountAln'
    ]    
    
    # run_accession, command, db, db_version, run_date, kma_version
    mapstatHeader = [header[0], header[-1], header[1], header[2], header[4], header[3]]
    mapstatHeader = ",".join([f"'{mh}'" for mh in mapstatHeader])
    return mapstatData[mapstatColumnOrder], mapstatHeader, header[1]

def insert_mapstat(mapstatData, mapstatHeader, table):

    # insert sql command for header
    q1 = "mysql -e \"use AvA_2; INSERT IGNORE INTO mapstat_header VALUES ({});\"".format(mapstatHeader)
    subprocess.run(q1, shell=True)
    
    # insert mapstat data in correct table
    with tempfile.NamedTemporaryFile(mode='w') as f:
        mapstatData.to_csv(f.name, index=False, line_terminator='|')
        f.flush()

        q2 = f"mysql -e \"use AvA_2; LOAD DATA LOCAL INFILE '{f.name}' INTO TABLE mapstat_data_{table} FIELDS TERMINATED BY ',' LINES TERMINATED BY '|' IGNORE 1 ROWS;\""
        subprocess.run(q2, shell=True)

if __name__ == "__main__":
    args = parse_args()

    for f in args.datafiles:
        md, mh, t = load_mapstat(f)
        insert_mapstat(md, mh, t)
    


