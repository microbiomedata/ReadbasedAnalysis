FROM continuumio/miniconda3:latest

LABEL developer="Po-E Li"
LABEL email="po-e@lanl.gov"
LABEL version="1.0.8"
LABEL software="nmdc_taxa_profilers"
LABEL tags="metagenome, bioinformatics, NMDC, taxonomy"

ENV container=docker

# system updates
RUN apt-get update --allow-releaseinfo-change \
    && apt-get install -y build-essential \
    && apt-get clean

# add conda channels
RUN conda config --add channels conda-forge \
    && conda config --add channels bioconda

# install singlem
RUN conda create -n singlem singlem \
    && conda clean --all -y

# install gottcha2
RUN conda create -n gottcha2 gottcha2=2.1.8.8 \
    && conda clean --all -y

# install kraken2
RUN conda create -n kraken2 kraken2=2.1.2 \
    && conda clean --all -y

# install centrifuge
RUN conda create -n centrifuge centrifuge=1.0.4_beta \
    && conda clean --all -y

# install krona
# The "curl" 
RUN conda install curl krona \
    && conda clean --all -y \
    && ktUpdateTaxonomy.sh

# install additional libs
RUN conda install pandas click && conda clean --all -y
ADD *.py /opt/conda/bin/

CMD ["/bin/bash"]
