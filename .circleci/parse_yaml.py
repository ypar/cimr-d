
"""Reading and parsing through the contributor's yaml file.
(c) YoSon Park

This is the default uploading skim for single and bulk files 
using zenodo. For PR-based file uploader, check .circleci/deploy.sh 
and .circleci/process_submitted_data.py
"""


import sys
import yaml
import pandas
import pathlib
import logging


CONFIG_FILE_EXTENSION = ('yml', 'yaml')
# transparent compressions recognized by tarfile 'r:*' are:
# gzip, bz2, and lzma (xz)
COMPRESSION_EXTENSION = ('gz', 'bz2', 'xz')
BULK_EXTENSION = ('tgz', 'tar.gz', 'tar.bz2', 'tar.xz')
FILE_EXTENSION = ('txt', 'tsv', 'txt.gz', 'tsv.gz')

logging.basicConfig(level='INFO')


def check_yaml_before_commit():
    """A git-status-dependent function used when locally applying 
    parse_yaml.py. It searches for a new or modified yml/yaml file and 
    returns its pathlib path.
    """
    import subprocess

    status_check = 'git status --porcelain'
    jobsplit = subprocess.check_output(
        status_check,
        stderr=subprocess.STDOUT,
        shell=True,
        universal_newlines=True
    ).replace('\n', '').split('?? ')

    for job in jobsplit:
        if job.endswith(CONFIG_FILE_EXTENSION):
            yaml_file = pathlib.Path('.cimr-d/' + job.split('/')[-1])

    return yaml_file


def check_yaml_in_ci():
    """A git-status-dependent function used during ci processing. It 
    searches for a new or modified yml/yaml file from a new pr"""
    import subprocess

    status_check = 'git diff origin --name-only'
    jobsplit = subprocess.check_output(
        status_check,
        stderr=subprocess.STDOUT,
        shell=True,
        universal_newlines=True
    ).split('\n')

    for job in jobsplit:
        if job.endswith(CONFIG_FILE_EXTENSION):
            yaml_file = pathlib.Path('.cimr-d/' + job.split('/')[-1])

    return yaml_file


def predefine_yaml():
    """A git-status-independent function used for cimr-d processing
    of a user-submitted yaml."""
    return pathlib.Path('upload_data_example.yml')


def load_yaml(yaml_file):
    """Read the found yaml file and return the read object."""
    with open(yaml_file, 'r') as args:
        try:
            return yaml.safe_load(args)
        except yaml.YAMLError as exc:
            logging.error(f' {exc}')
            sys.exit(1)


def validate_data_type(data_type):
    """Validate data_type variable for cimr compatibility."""
    DATA_TYPES = ('gwas', 'twas', 'eqtl', 'sqtl', 'pqtl', 'tad', 'multiple')
    if data_type in DATA_TYPES:
        return True
    else:
        logging.error(f' check your data_type.')
        sys.exit(1)


def verify_weblink(path):
    """Verify the provided link to the contributed file."""
    import urllib

    weburl = urllib.request.urlopen(path)

    if weburl.getcode() == 200:
        return True
    else:
        return False


def download_file(path, outdir='./'):
    """Download data based on the provided link.

    Note;
    Progress bars added based on the following reference:
    https://stackoverflow.com/questions/37573483/progress-bar-while-download-file-over-http-with-requests/37573701
    """
    from tqdm import tqdm
    import requests
    import math
    
    r = requests.get(path, stream=True)
    total_size = int(r.headers.get('content-length', 0))
    block_size = 1024
    wrote = 0
    file_name = path.split('/')[-1]
    file_path = outdir + file_name
    
    with open(file_path, 'wb') as f:
        for data in tqdm(r.iter_content(block_size), 
                         total=math.ceil(total_size//block_size), 
                         unit='KB', 
                         leave=True,
                         ncols=42,
                         unit_scale=True,
                         unit_divisor=1024):
            wrote = wrote + len(data)
            f.write(data)
    
    if total_size != 0 and wrote != total_size:
        logging.error(f' check the file link and try again.')
        sys.exit(1)


def validate_hash(path, hash):
    """Validate a file against an MD5 hash value."""
    import hashlib

    md5 = hashlib.md5()
    
    with open(path, 'rb') as f:
        while True:
            chunk = f.read(10000000)
            if not chunk:
                break
            md5.update(chunk)
    
    return md5.hexdigest() == hash


class Yamler:
    """A collection of utilities to parse the yaml file, check metadata
    and trigger cimr processing of the contributed file
    """

    def __init__(self, yaml_data):
        self.yaml_data = yaml_data
        self.data_type = None
        self.keys = None
        self.hash = None
        self.outdir = None
        self.downloaded_file = None


    def pick_keys(self):
        """List keys for the dictionarized yaml data and store in self.
        The following keys are expected:
        ['defined_as', 'data_file', 'contributor', 'data_info', 'method']
        """
        self.keys = self.yaml_data.keys()


    def set_data_type(self):
        """Pull out data_type variable value from yaml"""
        try:
            data_type = self.yaml_data['data_info']['data_type']
            if validate_data_type(data_type):
                self.data_type = data_type
        except ValueError:
            logging.error(f' there is no data_type indicated.')
            sys.exit(1)


    def download(self):
        """Check if provided weblink to the file exists. 
        Download if verified.
        """
        path = self.yaml_data['data_file']['location']['url']
        self.downloaded_file = path.split('/')[-1]

        outdir_root = 'submitted_data/'
        pathlib.Path(outdir_root).mkdir(exist_ok=True)
        self.outdir = outdir_root + str(self.data_type) + '/'
        pathlib.Path(self.outdir).mkdir(exist_ok=True)

        if verify_weblink(path):
            logging.info(f' starting download')
            download_file(path, self.outdir)
            self.hash = self.yaml_data['data_file']['location']['md5']
            self.downloaded_file = self.outdir + self.downloaded_file
        else:
            logging.error(f' file unavailable')
            sys.exit(1)


    def bulk_download(self):
        """Bulk download option assumes one of the following file types:
        ['tgz', 'tar.gz', 'tar.bz2', 'tar.xz']
        """
        import os
        import tarfile

        self.download()

        if tarfile.is_tarfile(self.downloaded_file):
            tarred_data = tarfile.open(
                self.downloaded_file, 
                mode='r:*'
            )
            for member in tarred_data.getmembers():
                if member.isreg():
                    member.name = os.path.basename(member.name)
                    tarred_data.extract(member, path=self.outdir)
    

    def check_hash(self):
        """Compare md5 of the downloaded file to the provided value"""
        if validate_hash(self.downloaded_file, self.hash):
            logging.info(f' data is ready for cimr processing.')
        else:
            raise ValueError(' provided md5 hash didn\'t match.')


    def check_defined(self):
        import os

        """Check whether the submitted data is a single file"""
        if self.yaml_data['defined_as'] == 'upload':
            self.download()
            self.check_hash()
        elif self.yaml_data['defined_as'] == 'upload_bulk':
            self.bulk_download()
            if self.check_hash():
                os.remove(self.outdir + self.downloaded_file)
        else:
            logging.error(f' accepted \'defined_as\' variables are \'upload\' and \'upload_bulk\'.')
            sys.exit(1)


    def check_data_file(self):
        """Standard set of Yamler functions to check information on the
        contributed data file for ci cimr processing.
        """
        self.set_data_type()
        self.check_defined()


if __name__ == '__main__':

    if len(sys.argv) == 1:
        yaml_file = predefine_yaml()
    else:
        yaml_file = pathlib.Path(sys.argv[1])

    try:
        yaml_file_path = yaml_file.resolve(strict=True)
    except FileNotFoundError:
        logging.info(f' no new yaml file found to process.')
        sys.exit(0)

    logging.info(f' processing metadata {yaml_file_path}.')
    yaml_data = load_yaml(yaml_file)
    print(yaml_data)
    y = Yamler(yaml_data)
    y.check_data_file()

