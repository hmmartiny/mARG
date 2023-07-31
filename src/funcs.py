import subprocess
import pandas as pd
from io import StringIO

def query_db(query, args=''):
    cmd = "mysql {} -e \"{}\"".format(args, query)
    p = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    if p.returncode > 0:
        print("Failed to query database with error:")
        print(p.stderr.decode())
    
    else:
        df = pd.read_csv(StringIO(p.stdout.decode()), sep='\t')
        return df