import subprocess
import pandas as pd
from io import StringIO

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
        df = pd.read_csv(o)
        return df
    elif p.returncode != 0:
        raise failedQuery(f"Failed to connect to database with error:\n{p.stderr.decode()}")