import os
import pandas as pd

from .funcs import query_db

class Updater:
    def __init__(self, records, verbose=False):
        if os.path.isfile(records):
            self.records = pd.read_csv(records)
        else:
            self.records = records

        self.verbose=verbose

    

    def update_ids(self, columns=['run_accession', 'sample_accession', 'study_accession']):
        
        tfname = 'ids.csv'
        self.records[columns].to_csv(tfname, index=None, header=None, sep=',')
        query = f"use AvA_2; LOAD DATA LOCAL INFILE '{tfname}' IGNORE INTO TABLE ids FIELDS TERMINATED BY ',' LINES TERMINATED BY '{os.linesep}'"
        query_db(query=query, verbose=self.verbose)
        os.remove(tfname)
