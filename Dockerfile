FROM continuumio/miniconda3:latest

LABEL developer="Po-E Li"
LABEL email="po-e@lanl.gov"
LABEL version="1.0.5"
LABEL software="nmdc_taxa_profilers"
LABEL tags="metagenome, bioinformatics, NMDC, taxonomy"

ENV container docker

# system updates
RUN apt-get update --allow-releaseinfo-change \
    && apt-get install -y build-essential \
    && apt-get clean

# add conda channels
RUN conda config --add channels conda-forge \
    && conda config --add channels bioconda

# install singlem
RUN wget https://github.com/wwood/singlem/archive/refs/tags/v0.15.0.tar.gz \
    && tar -xzf v0.15.0.tar.gz
RUN conda env create -n singlem -f singlem-0.15.0/singlem.yml \
    && ln -s ${PWD}/singlem-0.15.0/bin/* /opt/conda/envs/singlem/bin/
RUN rm -f v0.15.0.tar.gz

# install gottcha2
RUN wget https://github.com/poeli/GOTTCHA2/archive/refs/tags/2.1.8.5.tar.gz \
    && tar -xzf 2.1.8.5.tar.gz
RUN conda env create -n gottcha2 -f GOTTCHA2-2.1.8.5/environment.yml \
    && cp GOTTCHA2-2.1.8.5/gottcha/scripts/*.py /usr/local/bin
RUN rm -rf GOTTCHA2-2.1.8.5/ 2.1.8.5.tar.gz

# install kraken2
RUN conda create -n kraken2 kraken2=2.1.2

# install centrifuge
RUN conda create -n centrifuge centrifuge=1.0.4_beta

# install krona
# The "curl" 
RUN conda install curl krona \
    && ktUpdateTaxonomy.sh

# install additional libs
RUN conda install pandas click
ADD *.py /opt/conda/bin/

CMD ["/bin/bash"]
