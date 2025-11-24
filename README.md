# Metagenome Read-based Taxonomy Classification Workflow

![Workflow Diagram](docs/rba_workflow2025.svg)

## Workflow Overview

This pipeline profiles sequencing files (single- or paired-end, long- or short-read) using modular, selectable taxonomic classification tools. It supports **GOTTCHA2**, **Kraken2**, **Centrifuge**, and **SingleM** via Cromwell (WDL) and Docker, enabling scalable, reproducible metagenome analysis.

## Supported Tools

- [GOTTCHA2](https://github.com/microbiomedata/GOTTCHA2)
- [Kraken2](https://github.com/DerrickWood/kraken2)
- [Centrifuge](https://github.com/infphilo/centrifuge)
- [SingleM](https://github.com/wwood/SingleM)

Flexible selection of one or more tools via workflow input variables. Each profiler must be enabled via JSON, and paths to reference databases are required.

## Workflow Availability

- [GitHub Repository](https://github.com/microbiomedata/ReadbasedAnalysis)
- Docker Images:
    - `microbiomedata/nmdc_taxa_profilers`
    - `wwood/singlem:0.20.2`
    - `microbiomedata/bbtools:38.96`


## Requirements for Execution

**Recommendations are in bold**

- WDL-capable Workflow Execution Tool (**Cromwell**)
- Container Runtime that can load Docker images (**Docker v2.1.0.3 or higher**)


## Hardware Requirements

- **Disk space**: 152 GB for databases (55 GB for GOTTCHA2, 89 GB for Kraken2, and 8 GB for Centrifuge databases). SingleM public marker database is native to the SingleM container.
- **RAM**: 60 GB


## Workflow Dependencies

Third-party software (included in the Docker image):

- GOTTCHA2 v2.1.8.5 (License: BSD-3-Clause-LANL)
- Kraken2 v2.1.2 (License: MIT)
- Centrifuge v1.0.4 (License: GPL-3)
- SingleM v0.20.2 (License: GPL-3)


### Requisite Databases

You must download and install each tool's database to use that tool (total: 152 GB):

- **GOTTCHA2 database (gottcha2/):**
    - RefSeqr90.cg.BacteriaArchaeaViruses.species.fna contains complete genomes of bacteria, archaea and viruses from RefSeq Release 90.
    - Download commands:

```bash
wget https://edge-dl.lanl.gov/GOTTCHA2/RefSeq-r90.cg.BacteriaArchaeaViruses.species.tar
tar -xvf RefSeq-r90.cg.BacteriaArchaeaViruses.species.tar
rm RefSeq-r90.cg.BacteriaArchaeaViruses.species.tar
```

- **Kraken2 database (kraken2/):**
    - Standard Kraken 2 database, built from NCBI RefSeq genomes.
    - Download commands:

```bash
mkdir kraken2
wget https://genome-idx.s3.amazonaws.com/kraken/k2_standard_20201202.tar.gz
tar -xzvf k2_standard_20201202.tar.gz -C kraken2
rm k2_standard_20201202.tar.gz
```

- **Centrifuge database (centrifuge/):**
    - Compressed database built from RefSeq genomes of Bacteria and Archaea.
    - Download commands:

```bash
mkdir centrifuge
wget https://genome-idx.s3.amazonaws.com/centrifuge/p_compressed_2018_4_15.tar.gz
tar -xzvf p_compressed_2018_4_15.tar.gz -C centrifuge
rm p_compressed_2018_4_15.tar.gz
```


## Sample Datasets

- **Soil microbial communities** (East River watershed near Crested Butte, Colorado, US) — ER_DNA_379 metagenome ([SRR8553641](https://www.ncbi.nlm.nih.gov/sra/SRR8553641)) with metadata in the [NMDC Data Portal](https://data.nmdc.org). This dataset has 18.3G bases. Zipped raw fastq file is available [here](link).
- **Zymobiomics mock-community DNA control** ([SRR7877884](https://www.ncbi.nlm.nih.gov/sra/SRR7877884)), dataset has 6.7G bases.
    - Non-interleaved raw fastq files: [R1](link) and [R2](link)
    - Interleaved raw fastq file available [here](link)
    - 10% subset of interleaved fastq available [here](link)


## Input

A JSON file containing:

1. Selection of profiling tools (optional, default only singlem set true)
2. Paths to the required database(s) for the selected tools
3. Paths to the input fastq file(s) (paired-end data shown; output of the Reads QC workflow in interleaved format can be treated as single-end.)
4. Paired end Boolean
5. The project name
6. Long reads Boolean
7. CPU number requested for the run
```json
{
   "ReadbasedAnalysis.enabled_tools": {
     "gottcha2": false,
     "kraken2": false,
     "centrifuge": false,
     "singlem": true
   },
   "ReadbasedAnalysis.db": {
     "gottcha2": "/path/to/database/RefSeq-r90.cg.BacteriaArchaeaViruses.species.fna",
     "kraken2": "/path/to/kraken2",
     "centrifuge": "/path/to/centrifuge/p_compressed"
   },
   "ReadbasedAnalysis.reads": "/path/to/SRR7877884-int.fastq.gz",
   "ReadbasedAnalysis.paired": true,
   "ReadbasedAnalysis.proj": "SRR7877884",
   "ReadbasedAnalysis.long_read": false,
   "ReadbasedAnalysis.cpu": 8
}
```


## Output

The workflow creates an output JSON file and individual output sub-directories for each tool, which include tabular classification results, a tabular report, and a Krona plot (HTML).


| Directory/File Name | Description |
| :-- | :-- |
| SRR7877884_profiler.info | ReadbasedAnalysis profiler info JSON file |
| SRR7877884_centrifuge_classification.tsv | Centrifuge output read classification TSV file |
| SRR7877884_centrifuge_report.tsv | Centrifuge output report TSV file |
| SRR7877884_centrifuge_krona.html | Centrifuge krona plot HTML file |
| SRR7877884_gottcha2_full.tsv | GOTTCHA2 detail output TSV file |
| SRR7877884_gottcha2_report.tsv | GOTTCHA2 output report TSV file |
| SRR7877884_gottcha2_krona.html | GOTTCHA2 krona plot HTML file |
| SRR7877884_kraken2_classification.tsv | Kraken2 output read classification TSV file |
| SRR7877884_kraken2_report.tsv | Kraken2 output report TSV file |
| SRR7877884_kraken2_krona.html | Kraken2 krona plot HTML file |
| SRR7877884_singlem_classification.tsv | SingleM output read classification TSV file |
| SRR7877884_singlem_report.tsv | SingleM output report TSV file |
| SRR7877884_singlem_krona.html | SingleM krona plot HTML file |

## Version History

- **1.1.0** (release date 11/23/2025)


## Point of Contact

- Package maintainers: Chienchi Lo, Po-E Li, Valerie Li


