The Read-based Taxonomy Classification Workflow
================================================

.. image:: docs/rba_workflow2024.svg
   :align: center

Workflow Overview
-----------------
This pipeline profiles sequencing files (single- or paired-end, long- or short-read) using modular, selectable taxonomic classification tools. It supports GOTTCHA2, Kraken2, Centrifuge, and SingleM via Cromwell (WDL) and Docker, enabling scalable, reproducible metagenome analysis.

Supported tools
---------------

- `GOTTCHA2 <https://github.com/poeli/GOTTCHA2>`_
- `Kraken2 <http://ccb.jhu.edu/software/kraken2>`_
- `Centrifuge <http://www.ccb.jhu.edu/software/centrifuge>`_
- `SingleM <https://github.com/wwood/singlem>`_

Flexible selection of one or more tools via workflow input variables. Each profiler must be enabled via JSON, and paths to reference databases are required.


Workflow Availability
---------------------
The workflow is available in GitHub: https://github.com/microbiomedata/ReadbasedAnalysis; the corresponding Docker image is available in DockerHub: 

- `microbiomedata/nmdc_taxa_profilers <https://hub.docker.com/r/microbiomedata/nmdc_taxa_profilers>`_
- `wwood/singlem:0.20.2 <https://hub.docker.com/r/wwood/singlem>`_
- `microbiomedata/bbtools:38.96 <https://hub.docker.com/r/microbiomedata/bbtools>`_

Requirements for Execution:  
~~~~~~~~~~~~~~~~~~~~~~~~~~~

(recommendations are in **bold**)

- WDL-capable Workflow Execution Tool (**Cromwell**)
- Container Runtime that can load Docker images (**Docker v2.1.0.3 or higher**)

Hardware Requirements:
~~~~~~~~~~~~~~~~~~~~~~
- Disk space: 152 GB for databases (55 GB, 89 GB, and 8 GB for GOTTCHA2, Kraken2 and Centrifuge databases, respectively). SingleM public marker database (native to SingleM container).
- 60 GB RAM

Workflow Dependencies
---------------------

Third party software:
~~~~~~~~~~~~~~~~~~~~~

(These are included in the Docker image.)

- `GOTTCHA2 v2.1.8.5 <https://github.com/poeli/GOTTCHA2>`_  (License: `BSD-3-Clause-LANL <https://github.com/poeli/GOTTCHA2/blob/master/LICENSE>`_)
- `Kraken2 v2.1.2 <http://ccb.jhu.edu/software/kraken2>`_ (License: `MIT <https://github.com/DerrickWood/kraken2/blob/master/LICENSE>`_)
- `Centrifuge v1.0.4 <http://www.ccb.jhu.edu/software/centrifuge>`_ (License: `GPL-3 <https://github.com/DaehwanKimLab/centrifuge/blob/master/LICENSE>`_)
- `SingleM v0.20.2 <https://github.com/wwood/singlem>`_ (License: `GPL-3 <https://github.com/wwood/singlem/blob/master/LICENSE.txt>`_)

Requisite databases:
~~~~~~~~~~~~~~~~~~~~

The database for each tool must be downloaded and installed if you want to use that tool. These databases total 152 GB.

- GOTTCHA2 database (gottcha2/):

The database RefSeqr90.cg.BacteriaArchaeaViruses.species.fna contains complete genomes of bacteria, archaea and viruses from RefSeq Release 90. The following commands will download the database:

::

    wget https://edge-dl.lanl.gov/GOTTCHA2/RefSeq-r90.cg.BacteriaArchaeaViruses.species.tar
    tar -xvf RefSeq-r90.cg.BacteriaArchaeaViruses.species.tar
    rm RefSeq-r90.cg.BacteriaArchaeaViruses.species.tar

- Kraken2 database (kraken2/):

This is a standard Kraken 2 database, built from NCBI RefSeq genomes. The following commands will download the database:

::

    mkdir kraken2
    wget https://genome-idx.s3.amazonaws.com/kraken/k2_standard_20201202.tar.gz
    tar -xzvf k2_standard_20201202.tar.gz -C kraken2
    rm k2_standard_20201202.tar.gz

- Centrifuge database (centrifuge/):

This is a compressed database built from RefSeq genomes of Bacteria and Archaea. The following commands will download the database:

::

    mkdir centrifuge
    wget https://genome-idx.s3.amazonaws.com/centrifuge/p_compressed_2018_4_15.tar.gz 
    tar -xzvf p_compressed_2018_4_15.tar.gz -C centrifuge
    rm p_compressed_2018_4_15.tar.gz


Sample dataset(s):
~~~~~~~~~~~~~~~~~~

- Soil microbial communities from the East River watershed near Crested Butte, Colorado, United States - ER_DNA_379 metagenome (`SRR8553641 <https://www.ncbi.nlm.nih.gov/sra/SRX5355418>`_) with `metadata available in the NMDC Data Portal <https://data.microbiomedata.org/details/study/nmdc:sty-11-dcqce727>`_. This dataset has 18.3G bases

  - The zipped raw fastq file is available `here <https://portal.nersc.gov/cfs/m3408/test_data/SRR8553641/SRR8553641.fastq.gz>`_

- Zymobiomics mock-community DNA control (`SRR7877884 <https://www.ncbi.nlm.nih.gov/sra/SRX4716743>`_); this `dataset <https://portal.nersc.gov/cfs/m3408/test_data/SRR7877884/>`_ is has 6.7G bases.

  - The non-interleaved raw fastq files are available as `R1 <https://portal.nersc.gov/cfs/m3408/test_data/SRR7877884/SRR7877884_1.fastq.gz>`_ and `R2 <https://portal.nersc.gov/cfs/m3408/test_data/SRR7877884/SRR7877884_2.fastq.gz>`_
  - The interleaved raw fastq file is available `here <https://portal.nersc.gov/cfs/m3408/test_data/SRR7877884/SRR7877884-int.fastq.gz>`_
  - A 10% subset of the interleaved fastq is available `here <https://portal.nersc.gov/cfs/m3408/test_data/SRR7877884/SRR7877884-int-0.1.fastq.gz>`_

Input: 
~~~~~~

A JSON file containing the following information:

#. selection of profiling tools (set as true if selected)
#. the paths to the required database(s) for the tools selected 
#. the paths to the input fastq file(s) (paired-end data is shown; this can be the output of the Reads QC workflow in interleaved format which will be treated as single-end data.)
#. the prefix for the output file names
#. the path of the output directory
#. CPU number requested for the run.

.. code-block:: JSON

    {
        "ReadbasedAnalysis.enabled_tools": {
            "gottcha2": false,
            "kraken2": false,
            "centrifuge": false,
            "singlem": true
        },
        "ReadbasedAnalysis.db": {
            "gottcha2": "/path/to/database/RefSeq-r90.cg.BacteriaArchaeaViruses.species.fna",
            "kraken2": " /path/to/kraken2",
            "centrifuge": "/path/to/centrifuge/p_compressed"
        },
        "ReadbasedAnalysis.reads": "/path/to/SRR7877884-int.fastq.gz",
        "ReadbasedAnalysis.paired": true,
        "ReadbasedAnalysis.proj": "SRR7877884",
        "ReadbasedAnalysis.long_read": false,
        "ReadbasedAnalysis.cpu": 8
    }

Output:
~~~~~~~

The workflow creates an output JSON file and individual output sub-directories for each tool which include tabular classification results, a tabular report, and a Krona plot (html).

Below is an example of the output files with descriptions to the right.

.. list-table:: 
   :header-rows: 1

   * - Directory/File Name
     - Description
   * - SRR7877884_profiler.info
     - ReadbasedAnalysis profiler info JSON file
   * - SRR7877884_centrifuge_classification.tsv
     - Centrifuge output read classification TSV file
   * - SRR7877884_centrifuge_report.tsv
     - Centrifuge output report TSV file
   * - SRR7877884_centrifuge_krona.html
     - Centrifuge krona plot HTML file
   * - SRR7877884_gottcha2_full.tsv
     - GOTTCHA2 detail output TSV file
   * - SRR7877884_gottcha2_report.tsv
     - GOTTCHA2 output report TSV file
   * - SRR7877884_gottcha2_krona.html
     - GOTTCHA2 krona plot HTML file
   * - SRR7877884_kraken2_classification.tsv
     - Kraken2 output read classification TSV file
   * - SRR7877884_kraken2_report.tsv
     - Kraken2 output report TSV file
   * - SRR7877884_kraken2_krona.html
     - Kraken2 krona plot HTML file
   * - SRR7877884_singlem_classification.tsv
     - SingleM output read classification TSV file
   * - SRR7877884_singlem_report.tsv
     - SingleM output report TSV file
   * - SRR7877884_singlem_krona.html
     - SingleM krona plot HTML file


Version History
---------------

- 1.1.0 (release date 11/23/2025)

Point of contact
----------------
- Po-E Li, B10, LANL — po-e@lanl.gov
- Package maintainers: Chienchi Lo <chienchi@lanl.gov>
