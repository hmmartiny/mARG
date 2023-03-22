import os
import pandas as pd

from funcs import query_db, failedQuery

class Updater:
    def __init__(self, records, verbose=False):
        if os.path.isfile(records):
            self.records = pd.read_csv(records)
        else:
            self.records = records

        self.verbose=verbose

    def _load(self, tfname, table):
        """Load a csv file into a mysql table

        Parameters
        ----------
        tfname : str
            name of csv file
        table : str
            name of table the data is loaded into
        """
        query = f"use AvA_2; LOAD DATA LOCAL INFILE '{tfname}' IGNORE INTO TABLE {table} FIELDS TERMINATED BY ',' LINES TERMINATED BY '{os.linesep}'"
        query_db(query=query, verbose=self.verbose)

    def _insert(self, df, table, column_order):
        """Insert rows of a dataframe into a MySQL Table

        Parameters
        ----------
        df : pd.DataFrame
            pandas dataframe of data to be inserted
        table : str
            name of mysql table to insert data into
        column_order : list
            order of columns
        """

        values = []
        for _, row in df.iterrows():
            q = ",".join([f"\'{v}\'" for v in row[column_order].astype(str).values])
            values.append(f"({q})")
        
        query=f"use AvA_2; INSERT INTO {table}({','.join(column_order)}) VALUES {','.join(values)};"
        query_db(query)

    def ids(self, columns=['run_accession', 'sample_accession', 'study_accession']):
        tfname = 'ids.csv'
        try:
            self.records[columns].to_csv(tfname, index=None, header=None, sep=',')
            self._load(tfname, table='ids')
            os.remove(tfname)
        except failedQuery as e:
            self._insert(self.records[columns], table='ids', column_order=columns)
        except Exception as e:
            raise e
    
    def metadata(self, columns=[]):
        raise NotImplementedError
