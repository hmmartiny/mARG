import argparse
import pandas as pd
import numpy as np
import os
import re
from ete3 import NCBITaxa
import subprocess
from io import StringIO
import sys
from pysradb.sraweb import SRAweb


pd.options.display.max_colwidth = 100
ncbi = NCBITaxa()

def parse_args():
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument(
        '-d', '--data',
        type=str,
        required=True,
        help='Data file to work on',
        dest='data'
    )

    return parser.parse_args()

def splitter(str, searchfunc, char=' ', add_str=None):
    str = re.sub('\W', ' ', str).lower()
    splitstr= str.split(char)
    N = len(splitstr)

    results = []
    for i in range(N):
        for j in range(1, N+1):
            s = " ".join(splitstr[i:j]).strip()
            if len(s) > 0:
                results.append(s)
    results = list(set(results))

    if add_str is not None:
        results += [r + add_str for r in results]
    return searchfunc(results)

def get_tax(v):
    try:
        v2tax = ncbi.get_name_translator(v)
        return v2tax
    except AttributeError as e:
        print
        return None

def get_descendants(v):
    if not isinstance(v, list):
        v = list(v)
    try:
        v2tax = ncbi.get_name_translator(v)
    except AttributeError:
        return None

class Inspector:
    def __init__(self, records, initials='hanmar'):
        
        if os.path.isfile(records):
            self.records = pd.read_csv(records, index_col=0)
        else:
            self.records = records
        
        self.cleaned_records = self.records.copy()

        self.cleaned_log = pd.DataFrame(
            columns=[
                'run_accession', 'column', 
                'original_value', 'new_value', 
                'how', 
                'changed_by', 'changed_timestamp',
                'approved_by', 'approved_timestamp',
                'log_string'
            ]
        )

        # get sra metadata
        self.run_accessions = self.records['run_accession'].dropna().tolist()
        self.sra_metadata = self.check_SRA(accessions=self.run_accessions)

    def check_SRA(self, accessions):
        db = SRAweb()
        df = db.sra_metadata(accessions, detailed=True)
        return df

    def _stats(self, cols):
        s = []
        for c in cols:
            ss = f"column '{c}' contains {self.records[c].nunique()} unique values."
            ss += f" {self.records[c].isna().sum()} rows are empty."

            s.append(ss)
        print("\n".join(s))

    def approve(self, nrows, columns, inputvalues, choices):

        s = f"For {nrows} rows, attempting to guess the correct values of {columns}."
        s += f"\nBased on these input values:\n{inputvalues}"
        s += "\nChoices are: " 

        ilist = []
        for i, (k, v) in enumerate(choices.items()):
            s += f"\n {i}: {k} {v}"
            ilist.append(i)
        print(s)

        chosen=input(f"Which guess should be used? Enter one of the numbers from the list {ilist}: ")
        
        if len(chosen) == 0:
            ss = "None chosen, not correcting anything."
        else:
            chosen_values = list(choices.items())[int(i)]
            ss = f"Guess chosen: {chosen_values}"
        print(ss)
        s += "\n" + ss
        print("------------------------------------------------------------")

    
    def inspect_hosts(self, columns=['host', 'host_tax_id']):
        self._stats(columns)

        extra_cols=['sample_title', 'description_run', 'description_sample']

        # check what is missing
        for g, gdata in self.records.groupby(columns, dropna=False):
            nans = [pd.isnull(gg) for gg in g]
            if all(nans):
                for eg, egdata in gdata.groupby(extra_cols, dropna=False): 

                    possible_taxes = {}
                    sra_metadata = self.sra_metadata.loc[self.sra_metadata.run_accession.isin(egdata['run_accession']), ]
                    if sra_metadata is not None and not all(sra_metadata[['organism_taxid', 'organism_name']].isna()):
                        d = sra_metadata[['organism_taxid', 'organism_name']]
                        for rid, row in sra_metadata.dropna(subset=['organism_taxid', 'organism_name']).iterrows():
                            possible_taxes.update({row['organism_name']: row['organism_taxid']})
                        
                    for eeg in eg:            
                        pt = splitter(eeg, get_tax, add_str=' metagenome')    
                        if len(pt) == 1 and 'metagenome' in pt.keys():
                            pt = {}
                        possible_taxes.update(pt)
                    
                    if len(possible_taxes) > 0:                        
                        self.approve(
                            nrows=egdata.shape[0],
                            columns=columns,
                            inputvalues=pd.DataFrame.from_dict({c: v for c, v in zip(extra_cols, eg)}, orient='index'),
                            choices=possible_taxes)
            
                break
            
            #    continue

            # elif any(nans):
            #     print(g)
            #     taxes = get_tax(g)
            #     print(taxes)
            #     if taxes is None:
            #         print(gdata.T)
            # break

            # g = np.asarray(g)
            
            # if any(nans):
                
            #     nan_columns = np.where(nans, columns, np.empty_like(g, dtype=object))
            #     nan_columns = {c: c == v for c,v in zip(columns, nan_columns)}
            #     # nan_columns = nan_columns[nan_columns.astype(bool)]
            #     for k, v i nan_columns.items():

                # for i, nan_col in enumerate(nan_columns):
                #     if nan_col is None:
                #         continue
                #     if 'tax_id' in nan_col and g[i-1] not in nan_columns:
                #         print(get_tax_name(g[i-1]))
                
        # print(
        #     self.records.loc[
        #         (self.records[columns[0]].isna()),
        #         ['run_accession','host_tax_id_x', 'host', 'tax_id', 'description_x', 'description_y', 'study_title']
        #     ].sample(2).T
        # )
        

if __name__ == "__main__":

    args = parse_args()

    inspector = Inspector(args.data)
    inspector.inspect_hosts()
