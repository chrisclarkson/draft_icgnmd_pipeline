#!/usr/bin/env python3
import os
import argparse
import pandas as pd

def str2bool(v):
    if isinstance(v, bool):
        return v
    if v.lower() in ('yes', 'true', 't', 'y', '1'):
        return True
    elif v.lower() in ('no', 'false', 'f', 'n', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')

parser = argparse.ArgumentParser()

parser.add_argument('jaf', type=str, default=None)
parser.add_argument('--delimiter', type=str, default=None)
parser.add_argument('--separators', type=str, default=None, nargs="*")
parser.add_argument('--header', type=str2bool, default=False)
parser.add_argument('--dir', type=str, default='./')
parser.add_argument('--unfinished_jobs_out', help='unfinished_jobs.txt', type=str, default='unfinished_jobs.txt')
parser.add_argument('--prefix', type=str, default=None)
parser.add_argument('--cols', type=str, nargs="*", default=['1'])
parser.add_argument('--suffix', type=str, default=None)
parser.add_argument('--list_unfinished', type=str2bool, default=True)

args = parser.parse_args()

if args.delimiter is None:
    if args.header:
        jaf = pd.read_csv(args.jaf, sep='\t')
    else:
        jaf = pd.read_csv(args.jaf, sep='\t', header=None)
else:
    if args.header:
        jaf = pd.read_csv(args.jaf, sep=args.delimiter)
    else:
        jaf = pd.read_csv(args.jaf, sep=args.delimiter, header=None)

cols=args.cols

all_ints=[]
for i in range(len(cols)):
    int_or_not=cols[i].isdigit()
    all_ints.append(int_or_not)

if(sum(all_ints)==len(cols)):
    for i in range(len(cols)):
        cols[i]=int(cols[i])

jaf[cols]=jaf[cols].astype(str)
if args.separators is None:
    jaf['cols_added_together']=jaf[cols].agg('_'.join, axis=1)
else:
    if len(args.separators)!=len(cols)-1:
        print('incompatible number of separators vs columns')
    jaf['cols_added_together']=''
    for sepn in range(len(args.separators)):
        jaf['cols_added_together']=jaf['cols_added_together']+jaf[cols[sepn]]+args.separators[sepn]
    jaf['cols_added_together']=jaf['cols_added_together']+jaf[cols[sepn+1]]

if not args.dir.endswith('/'):
    args.dir=args.dir+'/'

if args.prefix is not None:
    jaf['cols_added_together']=args.dir+args.prefix+jaf['cols_added_together']

if args.suffix is not None:
    jaf['cols_added_together']=jaf['cols_added_together']+args.suffix

if args.list_unfinished:
    jaf['file_exists']=jaf['cols_added_together'].map(os.path.isfile)
    jaf=jaf.loc[~jaf['file_exists']].copy()

# jaf=jaf.drop_duplicates()
print(jaf.shape[0])
if args.unfinished_jobs_out=='None':
    print('unfinished jobs')
    idx=pd.Series(jaf.index)+1
    print(idx.to_list())
else:
    # jaf=jaf[cols].copy()
    print(args.unfinished_jobs_out)
    if args.delimiter is None:
        jaf.to_csv(args.unfinished_jobs_out,sep='\t',index=False,header=False)
    else:
        jaf.to_csv(args.unfinished_jobs_out,sep=args.delimiter,index=False,header=False)

# check_job_output.py chrom_ranges.txt --prefix ws_score_ --cols 0 1 2 --suffix .txt --dir ws_ranges
