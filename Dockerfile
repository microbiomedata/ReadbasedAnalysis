FROM continuumio/miniconda3:latest

LABEL developer="Po-E Li"
LABEL email="po-e@lanl.gov"
LABEL version="1.0.4"
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
# using head version of main branch since latest release (v0.13.2.tar.gz) doesn't include yml file.
RUN wget https://github.com/wwood/singlem/archive/refs/heads/main.tar.gz \
    && tar -xzf main.tar.gz
RUN conda env create -n singlem -f singlem-main/singlem.yml \
    && ln -s ${PWD}/singlem-main/bin/* /opt/conda/envs/singlem/bin/
RUN rm -f main.tar.gz

# install gottcha2
RUN wget https://github.com/poeli/GOTTCHA2/archive/refs/tags/2.1.8.1.tar.gz \
    && tar -xzf 2.1.8.1.tar.gz
RUN conda env create -n gottcha2 -f GOTTCHA2-2.1.8.1/environment.yml \
    && cp GOTTCHA2-2.1.8.1/gottcha/scripts/*.py /usr/local/bin
RUN rm -rf GOTTCHA2-2.1.8.1/ 2.1.8.1.tar.gz

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
