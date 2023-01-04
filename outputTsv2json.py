#!/usr/bin/env python3
import os
import json
import pandas as pd
import numpy as np
import click

@click.command()
@click.option('--meta', type=click.File('r'), help='JSON of the metadata of output files')

def output2json(meta):
    """ Simple converter that takes TSV files to generate a summary JSON. """
    df = pd.DataFrame()
    out_dict = {}

    tsvfile_lod = json.load(meta)

    for tsvmeta in tsvfile_lod:
        if not tsvmeta: continue
        infile = tsvmeta['orig_rep_tsv']
        tool = tsvmeta['tool']
        idx_col = 'taxRank'
        read_cnt_col = 'numReads'
        df = pd.DataFrame()

        result = {
            'classifiedReadCount': 0,
            'speciesReadCount': 0,
            'speciesCount': 0,
            'taxonomyTop10': {},
            'rawResults': {}
        }

        def reduceDf(df, cols, ranks=['species','genus','family'], top=10):
            """
            Report top # rows of ranks respectively and return a dict

            df: results in dataframe
            cols: (rnk_col, name_col, read_count_col, abu_col, taxid_col)
            """
            (rnk_col, name_col, read_count_col, abu_col, taxid_col) = cols
            df[read_count_col] = df[read_count_col].astype(int)
            df[abu_col] = round(df[abu_col], 4)
            outdict = {}
            for rank in ranks:
                taxdf = df[df[rnk_col]==rank] \
                    .sort_values(read_count_col, ascending=False) \
                    .loc[:, [name_col, taxid_col, read_count_col, abu_col]] \
                    .rename(columns={name_col: 'name', read_count_col: 'read_count', abu_col: 'abundance'}) \
                    .set_index(taxid_col) \
                    .head(top) \
                    .to_dict('split')
                
                if 'index' in taxdf:
                    taxdf['taxID'] = taxdf.pop('index')
                
                outdict[rank] = taxdf
            
            return outdict

        # parsing results
        if tool == "gottcha2":
            try:
                df = pd.read_csv(infile, sep='\t')
            except:
                pass

            if len(df)>0:
                result['rawResults'] = df.set_index('TAXID').to_dict('split')
                result['classifiedReadCount'] = df[df['LEVEL']=='superkingdom'].READ_COUNT.sum()
                result['speciesReadCount'] = df[df['LEVEL']=='species'].READ_COUNT.sum()
                result['speciesCount'] = len(df[df['LEVEL']=='species'].index)
                result['taxonomyTop10'] = reduceDf(df, ['LEVEL', 'NAME', 'READ_COUNT', 'REL_ABUNDANCE', 'TAXID'])
        elif tool == "centrifuge":
            try:
                df = pd.read_csv(infile, sep='\t')
            except:
                pass

            if len(df)>0:
                df['abundance'] = df['abundance'].astype(float)
                df['abundance'] = df['abundance']/100
                result['rawResults'] = df.set_index('taxID').to_dict('split')
                result['classifiedReadCount'] = df.numUniqueReads.sum()
                result['speciesReadCount'] = df[df['taxRank']=='species'].numUniqueReads.sum()
                result['speciesCount'] = len(df[df['taxRank']=='species'].index)
                result['taxonomyTop10'] = reduceDf(df, ['taxRank', 'name', 'numReads', 'abundance', 'taxID'])
        elif tool == "kraken2":
            try:
                df = pd.read_csv(infile,
                            sep='\t', 
                            names=['abundance','numReads','numUniqueReads','taxRank','taxID','name'])
            except:
                pass

            if len(df)>0:
                df['abundance'] = df['abundance'].astype(float)
                df['abundance'] = df['abundance']/100
                df['name'] = df['name'].str.strip()
                result['rawResults'] = df.set_index('taxID').to_dict('split')
                result['classifiedReadCount'] = df[df['name']=='root'].numReads.values[0]
                result['speciesReadCount'] = df[df['taxRank']=='S'].numReads.sum()
                result['speciesCount'] = len(df[df['taxRank']=='S'].index)
                df['taxRank'] = df['taxRank'].str.replace(r'\bS\b', 'species', regex=True)
                df['taxRank'] = df['taxRank'].str.replace(r'\bG\b', 'genus', regex=True)
                df['taxRank'] = df['taxRank'].str.replace(r'\bF\b', 'family', regex=True)
                result['taxonomyTop10'] = reduceDf(df, ['taxRank', 'name', 'numReads', 'abundance', 'taxID'])

        # rename 'index' to 'taxID'
        if 'index' in result['rawResults']:
            result['taxID'] = result['rawResults'].pop('index')
        
        out_dict[tool] = result
    
    # print summary JSON
    def convert(o):
        if isinstance(o, np.generic): return o.item()  
        raise TypeError
    print(json.dumps(out_dict, indent=2, default=convert))

if __name__ == '__main__':
    output2json()
