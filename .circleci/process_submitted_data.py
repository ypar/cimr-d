#!/usr/bin/env python3

import os
import sys
import logging
import subprocess


logging.basicConfig(level=logging.INFO)


root_dir = 'submitted_data'
submitted_file_split = set()

for dir_, _, files in os.walk(root_dir):
    for file_name in files:
        rel_dir = os.path.relpath(dir_, root_dir)
        rel_file = os.path.join(root_dir, rel_dir, file_name)
        submitted_file_split.add(rel_file)


for submitted_file in submitted_file_split:

    if submitted_file.startswith('submitted_data'):
        dir_name, data_type, file_name = submitted_file.split('/')
        out_dir_name = 'processed_data'

        if not os.path.isdir(out_dir_name):
            os.makedirs(out_dir_name, exist_ok=True)
        if not os.path.isdir(out_dir_name + '/' + data_type):
            os.makedirs(out_dir_name + '/' + data_type, exist_ok=True)

        outfile = submitted_file.replace(dir_name, out_dir_name)

        if not os.path.isfile(outfile):
            if not data_type == 'tad':
                from cimr.processor.utils import Infiler
                infile = Infiler(
                    data_type, 
                    submitted_file, 
                    genome_build='b38', 
                    update_rsid=False, 
                    outfile=str(outfile),
                    chunksize=700000
                )
                infile.read_file()

                if data_type == 'eqtl':
                    from cimr.processor.query import Querier
                    genes = list(infile.list_genes())
                    queried = Querier(genes)
                    queried.form_query()

            else:
                logging.info(f' processed file already exists for {submitted_file}')
                logging.info(f' if reprocessing, delete {outfile} and file a new pull request')

