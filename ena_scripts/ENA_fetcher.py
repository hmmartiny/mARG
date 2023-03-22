import requests
import pandas as pd
import numpy as np
from funcs import failedQuery

class ENAfetcher:

    def __init__(self, url='https://www.ebi.ac.uk/ena/portal/api/search?'):

        self.base_url = url

        self.comma = "%2C%20"
        self.nleg = "%3E%3D" # >=
        self.leg = "%3C%3D" # <=
        self.AND = "%20AND%20"
        self.equal = "%3D" # =
        self.quote = "%22" # "


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
            'host_sex', 'host_phenotype', 'investigation_type', 'sample_title', 'scientific_name', 'sample_alias'
        ]
        self.envsample_fields = [
            'sample_accession', 'environment_biome',
            'environment_feature', 'environment_material',
            'environmental_package', 'host_tax_id'
        ] 

        self.analysis_assembly_fields = [
            'sample_accession', 'analysis_accession', 
            'generated_ftp', 'submitted_ftp',
        ]

        self.sample_fields_ext = self.sample_fields + self.envsample_fields

    def build_url(self, result, fields, query=None, download_format='json', dataPortal='ena', verbose=False, limit=0):
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
        url += f"dataPortal={dataPortal}"
        url += f"&download=false"
        url += f"&format={download_format}"
        url += f"&fields={fields}"
        url += f"&limit={limit}"
        url += f"&result={result}"

        if query is not None and len(query) > 0:
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
            raise failedQuery(f"Query failed {r.text} from url:\n{url}.")
        

    def get_readrun(self, date=None, top_date=None, min_reads=1e5, library_source='METAGENOMIC', library_strategy='WGS', library_selection='RANDOM', limit=0):
        """Retrieve records containg run_accession information published from DATE and onward until top_date.

        Parameters
        ----------
        date : str
            Date to retrieve data from. Format: YYYY-MM-DD
        top_date : str
            Date to retrieve date up until. Format YYYY-MM-DD
        min_reads : int, optional
            Minimum number of reads required to be in a file for it to be downloaded, by default: 1e5
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

        query = f"&query=library_source{self.equal}{self.quote}{library_source}{self.quote}"
        query += f"{self.AND}library_strategy{self.equal}{self.quote}{library_strategy}{self.quote}" 
        query += f"{self.AND}library_selection{self.equal}{self.quote}{library_selection}{self.quote}"
        # query += f"{self.AND}read_count{self.nleg}{int(min_reads)}" 

        if date is not None:
            query += f"{self.AND}first_public{self.nleg}{date}"
        
        if top_date is not None:
            query += f"{self.AND}first_public{self.leg}{top_date}"
        
        df = self.build_url(result='read_run', fields=self.comma.join(self.readrun_fields), query=query, limit=limit)
        
        if df is None:
            return pd.DataFrame()
        
        df['read_count'] = pd.to_numeric(df['read_count']).fillna(0)
        return df

        # n = df.shape[0]
        # filtering_str = f" * Matched {n} runs in ENA initially." 

        # # filter on minimum number of reads and that fastq_ftp should not be empty
        # df = df.loc[
        #     ~ (df.fastq_ftp.isna() ) & 
        #     (df.read_count >= min_reads )
        # ]

        # filtering_str += f'\n * Filtering for minimum number of reads (>= {min_reads}): removed {n-df.shape[0]}, {df.shape[0]} runs left.'
        # n = df.shape[0]

        # # cross check
        # if check_db is not None:
        #     df = df.loc[ ~ (df.run_accession.isin(check_db))]

        #     filtering_str += f'\n * Filtering runs that are already downloaded: removed {n-df.shape[0]}, {df.shape[0]} runs left.'
        #     n = df.shape[0]

        # return df, filtering_str, n

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
        
    def get_sampledata(self, sample_accessions, date=None, top_date=None):
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

        queries = []
        if date is not None:
            queries.append(f"first_public{self.nleg}{date}")
        
        if top_date is not None:
            queries.append(f"first_public{self.leg}{top_date}")

        query = None
        if len(queries) > 0:
            query = '&query=' + f"{self.AND}".join(queries)

        df = self.build_url(result='sample', fields=self.comma.join(self.sample_fields_ext), query=query)
        df = df.loc[df.sample_accession.isin(sample_accessions)]
        #df = self.get_loop(ids=sample_accessions, result='sample', fields=self.comma.join(self.sample_fields_ext), k=k, accession='sample_accession')
        return df#[self.sample_fields], df[self.envsample_fields]

    def get_assemblydata(self, sample_accessions=[]):

        query = f'&query=assembly_type{self.equal}{self.quote}primary metagenome{self.quote}'
        try:
            df = self.build_url(result='analysis', fields=self.comma.join(self.analysis_assembly_fields), query=query)

            if len(sample_accessions) > 0:
                df = df.loc[df['sample_accession'].isin(sample_accessions)]
            return df
        except pd.errors.EmptyDataError:
            return None