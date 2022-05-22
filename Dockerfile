FROM continuumio/miniconda3:latest

LABEL developer="Po-E Li"
LABEL email="po-e@lanl.gov"
LABEL version="1.0.3"
LABEL software="nmdc_taxa_profilers"
LABEL tags="metagenome, bioinformatics, NMDC, taxonomy"

ENV container docker

RUN apt-get update --allow-releaseinfo-change \
    && apt-get install -y build-essential \
    && apt-get clean

# add conda channels
RUN conda config --add channels conda-forge \
    && conda config --add channels bioconda

# install gottcha2
RUN conda install minimap2 pandas gawk curl
RUN wget https://github.com/poeli/GOTTCHA2/archive/refs/tags/2.1.8.1.tar.gz \
    && tar -xzf 2.1.8.1.tar.gz \
    && cp GOTTCHA2-2.1.8.1/gottcha/scripts/*.py /usr/local/bin \
    && rm -rf GOTTCHA2-2.1.8.1/ 2.1.8.1.tar.gz

# install kraken2
RUN conda create -n kraken kraken2=2.1.0

# install centrifuge
RUN conda create -n centrifuge centrifuge=1.0.4_beta

# install krona
RUN conda install krona \
    && ktUpdateTaxonomy.sh

# install additional libs
RUN conda install click
ADD *.py /opt/conda/bin/

CMD ["/bin/bash"]
