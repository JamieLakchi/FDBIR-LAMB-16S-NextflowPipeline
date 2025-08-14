"""
Filename: gtdb_auxilary_helpers.py
Date Created: 2025/08/05 
Last Update: 2025/08/06
Dependencies Bio (SeqIO), pandas
Description:
A program to create the extra files needed to create a custom emu (https://github.com/treangenlab/emu) database from a .fasta file.
Program tries to creat a .map and a .tsv, this program exists mainly to make it easier to fetch and process data from gtdb (https://gtdb.ecogenomic.org).
"""

import requests
import gzip
import shutil
import sys
import argparse
import subprocess
import pandas as pd
from Bio import SeqIO
from pathlib import Path

KINGDOM = 'superkingdom'
PHYLUM = 'phylum' 
CLASS = 'class'
ORDER = 'order'
FAMILY = 'family'
GENUS = 'genus'
SPECIES = 'species'
FULLTAXON = 'full_taxonomy'

TAXONOMYSTRING_ORDER = [KINGDOM, PHYLUM, CLASS, ORDER, FAMILY, GENUS, SPECIES]

def download_and_decompress(url, output_path):
    """
    Download a .gz file from a URL and decompress it.
    
    @param url URL to download from
    @param output_path Path where the compressed file should be saved
    @return Path to the decompressed file
    """
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        
        with open(output_path + ".gz", 'wb') as f:
            shutil.copyfileobj(response.raw, f)
            
    except:
        print("Error: Failed to download .gz file from", url, file=sys.stderr)
        sys.exit(1)
    
    try:        
        with gzip.open(output_path + ".gz", 'rb') as f_in:
            with open(output_path, 'wb') as f_out:
                shutil.copyfileobj(f_in, f_out)

        return output_path
        
    except Exception as e:
        print(f"Error: Failed to decompress {output_path}: {e}", file=sys.stderr)
        sys.exit(1)

def parse_taxonomy_string(taxonomy_string):
    """
    Parses a taxonomy string.
    A taxonomy string is a string that has a read's taxa as kingdom;phylum;...;species

    @param taxonomy_string a taxonomy string
    @return a dictionary with all the taxa seperated
    """
    parts = taxonomy_string.split(' ', 1)

    if len(parts) < 2:
        return {
            KINGDOM: '',
            PHYLUM: '',
            CLASS: '',
            ORDER: '',
            FAMILY: '',
            GENUS: '',
            SPECIES: '',
            FULLTAXON: ''
        }
    
    taxonomy_part = parts[1].split('[')[0].strip()
    tax_levels = taxonomy_part.split(';')
    result = {
            KINGDOM: '',
            PHYLUM: '',
            CLASS: '',
            ORDER: '',
            FAMILY: '',
            GENUS: '',
            SPECIES: '',
            FULLTAXON: taxonomy_part
        }
    
    for level, entry in zip(tax_levels, TAXONOMYSTRING_ORDER):
        level = level.strip()
        result[entry] = level
    
    return result

def create_output_files(seq2tax_data, taxonomy_data, tsv_output, map_output):
    """
    Creates the output files from generated data

    @param seq2tax_data list of accession-tax_id pairs
    @param taxonomy_data dict with tax_id and full taxon data kay-value pairs
    @param tsv_output name of where to output the .tsv file
    @param map_output name of where to output the .map file
    """
    seq2tax_df = pd.DataFrame(seq2tax_data, columns=['accession', 'tax_id'])
    seq2tax_df.to_csv(map_output, sep='\t', index=False, header=False)
    
    tax_records = []
    for tax_id, tax_info in taxonomy_data.items():
        record = {'tax_id': tax_id}
        record.update(tax_info)
        tax_records.append(record)
    
    taxonomy_df = pd.DataFrame(tax_records)
    taxonomy_df.to_csv(tsv_output, sep='\t', index=False)

def parse_fasta_to_taxonomy(fasta_file, tsv_output, map_output):
    """
    Creates the wanted .map and .tsv files from a .fasta file

    @param fasta_file name of the input .fasta file
    @param tsv_output name of where to output the .tsv file
    @param map_output name of where to output the .map file
    """
    seq2tax_data = []
    taxonomy_data = {} 
    tax_id_counter = 1
    seen_taxa = {}

    print("started parse")
    
    with open(fasta_file) as handle:
        for record in SeqIO.parse(handle, "fasta"):
            accession = record.id
            description = record.description
            tax_components = parse_taxonomy_string(description)
            taxonomy = tax_components[FULLTAXON]
            
            if taxonomy not in seen_taxa.keys():
                print("found new FULLTAXON: ", taxonomy)
                current_tax_id = tax_id_counter
                seen_taxa[taxonomy] = current_tax_id
                taxonomy_data[current_tax_id] = tax_components
                
                tax_id_counter += 1
            else:
                current_tax_id = seen_taxa[taxonomy]
            
            seq2tax_data.append([accession, current_tax_id])
    create_output_files(seq2tax_data, taxonomy_data, tsv_output, map_output)

def combine_fasta(files, outname, normalize_names):
    pass

if __name__ == "__main__":
    operation_opts = [
        "emudb_aux",
        "fasta_combine"
    ]

    argparser = argparse.ArgumentParser()
    argparser.add_argument("operation", help="""
                           select operation, either "emudb_aux" or "fasta_combine"
                           emudb_aux: generates the auxilary files from a .fasta file to create an emu database
                           fasta_combine: takes multiple fasta files and combines them
                           """, action="store", default=None)
    argparser.add_argument("--fasta_fetch", help="[emudb_aux] takes a link, if specified the program will try to download a .fna.gz from that location and generate a .tsv and .map from there", action="store", default=None)
    argparser.add_argument("--fasta_name", help="[emudb_aux/fasta_combine] specify where a fasta file is located, used as filename when using fasta_fetch (only looks at first name when operation is emudb_aux)", nargs="+", action="store", default="gtdblatest_bac120.fasta")
    argparser.add_argument("--normalize_taxa", help="[fasta_combine] if present appends x__ to taxa if not yet there (ex: d__Bacteria, p__Pseudomonadota)", action="store_true", default=False)
    argparser.add_argument("--fasta_out", help="[fasta_combine] name for output file", action="store", default=None)
    argparser.add_argument("--map_name", help="[emudb_aux] specify the name of the .map file", action="store", default="seq2taxid.map")
    argparser.add_argument("--tsv_name", help="[emudb_aux] specify the name of the .tsv file", action="store", default="taxonomy.tsv")
    args = argparser.parse_args()

    if(args.operation not in operation_opts):
        raise f"Select a valid operation: {operation_opts}"
    
    fasta_file = args.fasta_name

        
    if(args.operation == "emudb_aux"):
        if(args.fasta_fetch != None):
            download_and_decompress(args.fasta_fetch, fasta_file)

        parse_fasta_to_taxonomy(fasta_file[0], args.tsv_name, args.map_name)

    elif(args.operation == "fasta_combine"):
        if(args.fasta_out == "none"):
            raise "Argument --fasta_out required for fasta_combine operation"
        
        combine_fasta(args.fasta_file, args.fasta_out, args.normalize_taxa)
    