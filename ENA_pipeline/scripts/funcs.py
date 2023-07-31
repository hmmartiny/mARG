import subprocess
import re
from collections import defaultdict
import pandas as pd
import os
import sys
from io import StringIO

def _read(filename):
    with open(filename, 'r') as f:
        content = [l.strip() for l in f.readlines()]

    return content

def _get(directory):
    files = os.listdir(directory)
    return files

def parse_raw(rawdir, res):
    
    if os.path.isfile(rawdir):
        rawfiles = _read(rawdir)
    else:
        rawfiles = _get(rawdir)
    
    p = re.compile(r'((E|D|S)RR[0-9]{6,})')
    for i, fname in enumerate(rawfiles):
        m = p.findall(fname)
        rid=m[0][0]

        res.loc[
            i, ['run_accession', 'file', 'folder', 'downloaded']
        ] = [
            rid, os.path.basename(fname), os.path.dirname(fname), 1 
        ]
def parse_trimmed(trimdir, res):
    
    if os.path.isfile(trimdir):
        trimfiles = _read(trimdir)
    else:
        trimfiles = _get(trimdir)

    p = re.compile(r'((E|D|S)RR[0-9]{6,}_\d)')

    for fname in trimfiles:
        if fname.endswith('.trim.fq.gz'):
            m = p.findall(fname)
            rid = m[0][0]
            res.loc[res['file'].str.contains(rid), 'trimmed'] = 1

def update_file_overview(rawdir, trimdir):
    
    res = pd.DataFrame(columns=[
        'run_accession',
        'file',
        'folder',
        'downloaded',
        'trimmed'
    ])

    res['downloaded'] = 0
    res['trimmed'] = 0
    
    parse_raw(rawdir, res)
    parse_trimmed(trimdir, res)

    return res

def run_foodpipeline(rawdir, trimtime=86400, run=True, verbose=True):
    """Wrapper function to start FoodQCPipeline.py script on Computerome2

    Parameters
    ----------
    rawdir : str
        raw directory path
    trimtime : int, optional
        time to run trim in seconds, by default 86400
    run : bool, optional
        Submit FoodQCPipeline command or test script functionality if false, by default True
    verbose : bool, optional
        Print statements, by default True

    Returns
    -------
    jobid : str
        JobId in queue
    """

    trimdir=rawdir.replace('raw', 'Trimmed')
    qcdir=rawdir.replace('raw', 'QC')
    tmpdir=rawdir.replace('raw', 'FoodQCPipeline_tmp')
    foodpipeline_cmd = [
        'python',
        '/home/projects/cge/apps/FoodQCPipeline.py',
        '--trim_output', trimdir,
        '--qc_output', qcdir,
        '--tmp_dir', tmpdir,
        #'--clean_tmp',
        '--trim_time', str(trimtime),
        os.path.join(rawdir, '*.fastq.gz')
    ]
    
    if verbose:
        print("Submitting:", " ".join(foodpipeline_cmd), file=sys.stdout)

    if run:
        out = subprocess.check_output(" ".join(foodpipeline_cmd), shell=True, stderr=subprocess.STDOUT)
        out = out.decode('utf-8')

        jobid = out.split('\n')[-3].split(':')[-1].split('.')[0].strip()
    else:
        jobid=None
    
    #submit_kma(rawdir=rawdir, jobid=jobid, run=run, verbose=verbose)

    return jobid

def submit_kma_intermediary(rawdir, jobid, run=True, verbose=True):
    """A wrapper function for a script that parses all jobs started by FoodQCPipeline

    Parameters
    ----------
    rawdir : str
        raw directory path
    jobid : str
        JobId in queue to wait for
    run : bool, optional
        If true, submit job to queue. If false, test functionality by printing selected statements. by default True
    verbose : bool, optional
        Verbosity statements are printed to STDOUT, by default True
    """

    idx=-2
    if rawdir.endswith(os.sep): idx=-3
    projdir=rawdir.split(os.sep)[idx]
    jobarg=''
    if jobid:
        # check if job has already finished?
        pc = subprocess.run('qstat -t {}'.format(jobid), shell=True, stdout=subprocess.PIPE)
        pco = pc.stdout.decode()
        if not ' C batch' in pco:
            jobarg='-W depend=afterok:{}'.format(jobid)

    submit_cmd=[
        'qsub',
        '-A', 'cge',
        '-W', 'group_list=cge',
        '-l', 'walltime=00:00:10:00,mem=20gb,nodes=1',
        '-v', 'RAWDIR="{}"'.format(rawdir),
        '-d', '$PWD',
        #'-W', 'depend=afterok:{}'.format(jobid),
        jobarg,
        '-e', 'kma_btw_{}.err'.format(projdir),
        '-N', 'kma_btw_{}.job'.format(projdir),
        'intermediary_kma.sh'
    ]

    if verbose:
        print("Submitting:", " ".join(submit_cmd), file=sys.stdout)

    if run:
        subprocess.run(" ".join(submit_cmd), shell=True)

def submit_kma(rawdir, jobid=None, run=True, verbose=True, no_clean=False):
    """Submit KMA jobs

    Parameters
    ----------
    rawdir : str
        directory with raw files
    jobid : str, optional
        JobID(s) in queue for FoodQCPipeline jobs, by default None
    run : bool, optional
        If true, run commands. If not, test functionality. by default True
    verbose : bool, optional
        Print statements, by default True
    no_clean : bool, optional
        If true, du not submit cleanup jobs. by default False
    """

    # make KMA dir
    kmadir = rawdir.replace('raw', 'kma')
    trimdir = rawdir.replace('raw', 'Trimmed')
    if run:
        os.makedirs(kmadir, exist_ok=True)

        # change permissions on kmadir
        subprocess.run("chmod 755 {}".format(kmadir), shell=True)
    
        # change group for kmadir to 'cge' (id=1039 on C2)
        subprocess.run("chgrp cge {}".format(kmadir), shell=True)

    # submit_cmd = [
    #     'python3',
    #     'start_kma.py',
    #     '--kmadir', kmadir,
    #     '--trimdir', rawdir.replace('raw', 'Trimmed'),
    # ]
    # if jobid:
    #     submit_cmd += [
    #         '--jobid', str(jobid)
    #     ]
    # if not run:
    
    #     submit_cmd += [
    #         '-t'
    #     ]
    
    projdir=kmadir.split(os.sep)[-3]
    if jobid:
        jobarg='-W depend=afterok:{}'.format(jobid)
    else:
        jobarg=''

    submit_cmd = [
        'qsub',
        '-A', 'cge',
        '-W', 'group_list=cge',
        '-l', 'walltime=00:00:10:00,mem=20gb,nodes=1',
        '-v', 'KMADIR="{}",TRIMDIR="{}",NOCLEAN="{}"'.format(kmadir, trimdir, no_clean),
        '-d', '$PWD',
        #'-W', 'depend=afterok:{}'.format(jobid),
        jobarg,
        '-e', 'submit_kma_{}.err'.format(projdir),
        '-N', 'submit_kma_{}.job'.format(projdir),
        'start_kma.sh'
    ]

    if verbose:
        print("Submitting:", " ".join(submit_cmd), file=sys.stdout)
    if run:
        subprocess.run(" ".join(submit_cmd), shell=True)


def query_db(cmd, return_df=True, **db_args):
    query = f"mysql -e \"{cmd}\""

    if  db_args.get('user'):
        query += f" -u {db_args['user']}"
    
    if db_args.get('passwd'):
        query += f" -p {db_args['passwd']}"
    
    if db_args.get('host'):
        query += f" -host {db_args['host']}"

    if db_args.get('db'):
        query += f" -D {db_args['db']}"

    p = subprocess.run(query, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
    
    if return_df:
        df =  pd.read_csv(StringIO(p.stdout.decode()), sep='\t')
        return df
    else:
        return p