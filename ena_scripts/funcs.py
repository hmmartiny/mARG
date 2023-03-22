import subprocess
import pandas as pd
from io import StringIO
from Bio import Entrez
import xml.etree.ElementTree as ET
from bs4 import BeautifulSoup as BS
import requests

class failedQuery(Exception):
    pass


def query_db(query, return_df=False, verbose=False):
    """ Query a MySQL database

    Parameters
    ----------
    query : string
        query to run
    return_df : bool, optional
        if True, convert the output of the query into a pandas dataframe, by default False
    verbose : bool, optional
        be verbose, by default False

    Returns
    -------
    pandas.dataframe
        optionally returns a pandas dataframe if the return_df argument is true

    Raises
    ------
    failedQuery
        raises error if mysql query failed
    """

    cmd = f"mysql --defaults-file=~/.my.cnf -e \"{query}\""
    p = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    
    if verbose:
        print(f"Queried database with command:\n {query}")
        print("Returncode:", p.returncode)
    
    if p.returncode == 0 and return_df is True:
        o = StringIO(p.stdout.decode())
        df = pd.read_csv(o, sep='\t')
        return df
    elif p.returncode != 0:
        raise failedQuery(f"Failed to connect to database with error:\n{p.stderr.decode()}")


def get_biosample(accession, email):

    Entrez.email = email
    
    handle = Entrez.efetch(db="sra", id=accession)
    tree = ET.parse(handle)
    root = tree.getroot()

    for sd in root.iter('SAMPLE'):
        sra_accession = sd.attrib['accession']
        sra_alias = sd.attrib['alias']

    url = f'https://www.ncbi.nlm.nih.gov/biosample/{sra_alias}' # https://www.ncbi.nlm.nih.gov/biosample/SAMD00002573
    r = requests.get(url)
    soup = BS(r.text)

    print(soup.find_all('td'))

    # get biosample info
    attributesDict = {'sra_accession': sra_accession, 'sra_alias': sra_alias}
    for acc in [sra_accession, sra_alias]:
        handle = Entrez.efetch(db="biosample", id=acc)
        tree = ET.parse(handle)
        root = tree.getroot()

        for attributes in root.iter('Attributes'):
            for metadata in attributes:
                attributesDict[metadata.attrib['attribute_name']] = metadata.text
    
    print(attributesDict)
