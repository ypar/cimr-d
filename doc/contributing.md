
# Table of Contents

- [Preparing a file for data contribution](#preparing-a-file-for-data-contribution)

- [Writing a yaml file for data contribution](#writing-a-yaml-file-for-data-contribution)

- [Arguments](#arguments)
  - [defined_as](#defined_as)
  - [data_file](#data_file)
  - [contributor](#contributor)
  - [data_info](#data_info)
  - [method](#method)

- [Examples](#examples)
  - [TWAS upload yaml file example](#twas-upload-yaml-file-example)
  - [GWAS upload example](#gwas-upload-example)

- [Frequently asked questions](#frequently-asked-questions)



# Preparing a file for data contribution




# Writing a yaml file for a weblink-based data contribution

_cimr-d_ accepts data previously uploaded to public archives such as 
[zenodo](https://zenodo.org/).




# Arguments

## defined_as

`defined_as` variable indicates whether the contributed data is a
single text file or a tarball containing multiple files.


| argument    | description             |
|-------------|-------------------------|
| upload      | single file upload yaml |
| upload_bulk | bulk file upload yaml   |

For `upload_bulk` option, all submitted files need to be archived as 
one of the following file types: `tar`, `tar.gz`, `tar.bz2`, and `tar.xz`.
***Important***: currently, cimr-d only processes tar files with no 
directory trees. 

One may produce a tar file containing all files with suffix `_gwas.txt` within 
the directory as follows:

```bash
tar czvf gwas.tar.gz *_gwas.txt
```

Then the file must be uploaded to a repository where cimr-d can access.



## data_file

`data_file` variable is a superset of variables describing the dataset. 


| argument                    | description                              |
|-----------------------------|------------------------------------------|
| doc                         | a brief description of data              | 
| location: url               | link to data                             |
| location: md5               | md5 sum hash to verify the file size     |
| compression                 | whether the file has been compressed     |
| keep_file_name              | whether the file name should be used     |
| output_name                 | data name, if not indicated as file name |
| columns: variant_id         | variant id in the format of              |
|                             | chromosome:position:ref:alt or           |
|                             | chromosome_position_ref_alt_build        |
| columns: variant_chromosome | variant chromosome id                    |
| columns: variant_position   | variant genomic position                 |
| columns: rsnum              | variant rs id                            |
| columns: reference_allele   | variant reference allele                 |
| columns: alternate_allele   | variant alternate allele                 |
| columns: effect_allele      | effect allele for statistic              |
| columns: effect_size        | effect size / beta coefficient           |
| columns: standard_error     | standard error of the effect size        |
| columns: statistic          | statistic used to estimate p-value       |
| columns: pvalue             | pvalue                                   |
| columns: feature_id         | feature id, if applicable (e.g. gene)    |
| columns: feature_chromosome | chromosome id, if applicable             |
| columns: feature_start      | starting genomic position, if applicable |
| columns: feature_stop       | stopping genomic position, if applicable |
| columns: comment_0          | other info (e.g. did statistic converge?)|




## contributor

Contributor information is optional but recommended.


| argument    | description                         |
|-------------|-------------------------------------|
| name        | name of the contributor             |
| github      | github user name of the contributor |
| email       | e-mail address of the contributor   |



## data_info 

Data information provided in `data_info` is used to generate citation 
and metadata information used for downstream analyses.


| argument      | description                                          |
|---------------|------------------------------------------------------|
| citation      | publication or data doi, if applicable               |
| data_source   | (permenant) link to the original data, if applicable |
| sample_size   | sample size of the study                             |
| cases         | number of cases, if applicable (e.g. binary trait)   |
| controls      | number of controls, if applicable                    |
| data_type     | data_type (e.g. twas, gwas, eqtl, etc.)              |
| can_be_public | whether the data can be posted publicly via cimr-d   |



## method 

Method details can be listed here.

| argument  | description                    |
|-----------|--------------------------------|
| name      | name of the method used        |
| tool      | name of the tool used          |
| website   | website link for the tool used |



# Examples


## TWAS upload yaml file example
This is an example yml configuration to upload TWAS data to cimr-d:


```yaml
defined_as: upload

data_file:
    doc: >
        Shared and distinct genetic risk factors for childhood-onset 
        and adult-onset asthma; genome-wide and transcriptome-wide 
        studies using predixcan
    location:
        url: https://zenodo.org/record/3248979/files/asthma_adults.logistic.assoc.tsv.gz
        md5: 358d9ac5a7b70633b6a9028331817c7b
    compression: true
    keep_file_name: false
    output_name: ukb_adult_asthma_predixcan_logistic
    columns:
        variant_id: variant
        variant_chromosome: chr
        variant_genomic_position: pos
        rsnum: rsid
        reference_allele: ref
        alternate_allele: alt
        effect_allele: na
        effect_size: beta
        standard_error: se
        statistic: zstat
        pvalue: pval
        gene_id: na
        gene_chromosome: na
        gene_start: na
        gene_stop: na
        comment_0: converged
        
contributor:
    name: YoSon Park
    github: ypar
    email: cimrroot@gmail.com

data_info:
    citation: 10.1016/S2213-2600(19)30055-4
    data_source: https://zenodo.org/record/3248979
    sample_size: 356083
    cases: 37846
    controls: 318237
    data_type: twas
    can_be_public: na

method:
    name: logistic regression
    tool: predixcan
    website: https://github.com/hakyimlab/PrediXcan 
```



## GWAS upload example





## Frequently asked questions

