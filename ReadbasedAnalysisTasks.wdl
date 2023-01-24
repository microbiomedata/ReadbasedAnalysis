task profilerGottcha2 {
    Array[File] READS
    String DB
    String PREFIX
    String? RELABD_COL = "ROLLUP_DOC"
    String DOCKER
    Int? CPU = 4

    command <<<
        set -euo pipefail
        . /opt/conda/etc/profile.d/conda.sh
        conda activate gottcha2

        gottcha2.py -r ${RELABD_COL} \
                    -i ${sep=' ' READS} \
                    -t ${CPU} \
                    -o . \
                    -p ${PREFIX} \
                    --database ${DB}
        
        grep "^species" ${PREFIX}.tsv | ktImportTaxonomy -t 3 -m 9 -o ${PREFIX}.krona.html - || true

        gottcha2.py --version > ${PREFIX}.info
    >>>
    output {
        File report_tsv = "${PREFIX}.tsv"
        File full_tsv = "${PREFIX}.full.tsv"
        File krona_html = "${PREFIX}.krona.html"
        File info = "${PREFIX}.info"
    }
    runtime {
        docker: DOCKER
        cpu: CPU
        node: 1
        nwpn: 1
        mem: "45G"
        time: "04:00:00"
    }
    meta {
        author: "Po-E Li, B10, LANL"
        email: "po-e@lanl.gov"
    }
}

task profilerCentrifuge {
    Array[File] READS
    String DB
    String PREFIX
    Int? CPU = 4
    String DOCKER

    command <<<
        set -euo pipefail
        . /opt/conda/etc/profile.d/conda.sh
        conda activate centrifuge
        
        centrifuge -x ${DB} \
                   -p ${CPU} \
                   -U ${sep=',' READS} \
                   -S ${PREFIX}.classification.tsv \
                   --report-file ${PREFIX}.report.tsv       

        ktImportTaxonomy -m 5 -t 2 -o ${PREFIX}.krona.html ${PREFIX}.report.tsv

        centrifuge --version | head -1 | cut -d ' '  -f3 > ${PREFIX}.info
    >>>
    output {
      File classification_tsv="${PREFIX}.classification.tsv"
      File report_tsv="${PREFIX}.report.tsv"
      File krona_html="${PREFIX}.krona.html"
      File info = "${PREFIX}.info"
    }
    runtime {
        docker: DOCKER
        cpu: CPU
        node: 1
        nwpn: 1
        mem: "45G"
        time: "04:00:00"
    }
    meta {
        author: "Po-E Li, B10, LANL"
        email: "po-e@lanl.gov"
    }
}

task profilerKraken2 {
    Array[File] READS
    String DB
    String PREFIX
    Boolean? PAIRED = false
    Int? CPU = 4
    String DOCKER

    command <<<
        set -euo pipefail
        . /opt/conda/etc/profile.d/conda.sh
        conda activate kraken2

        kraken2 ${true="--paired" false='' PAIRED} \
                --threads ${CPU} \
                --db ${DB} \
                --output ${PREFIX}.classification.tsv \
                --report ${PREFIX}.report.tsv \
                ${sep=' ' READS}
        conda deactivate        

        ktImportTaxonomy -m 3 -t 5 -o ${PREFIX}.krona.html ${PREFIX}.report.tsv
        # If no krona taxonomy, use following commands:
        # kreport2krona.py -r ${PREFIX}.report.tsv -o ${PREFIX}.krona.txt --no-intermediate-ranks
        # ktImportText ${PREFIX}.krona.txt -o ${PREFIX}.krona.html

        kraken2 --version | head -1 | cut -d ' '  -f3 > ${PREFIX}.info
    >>>
    output {
      File classification_tsv = "${PREFIX}.classification.tsv"
      File report_tsv = "${PREFIX}.report.tsv"
      File krona_html = "${PREFIX}.krona.html"
      File info = "${PREFIX}.info"
    }
    runtime {
        docker: DOCKER
        cpu: CPU
        node: 1
        nwpn: 1
        mem: "45G"
        time: "04:00:00"
    }
    meta {
        author: "Po-E Li, B10, LANL"
        email: "po-e@lanl.gov"
    }
}

task profilerSinglem {
    Array[File] READS
    String DB
    String PREFIX
    String DOCKER
    Boolean? PAIRED = false
    Int? CPU = 4

    command <<<
        set -euo pipefail
        . /opt/conda/etc/profile.d/conda.sh
        conda activate singlem

        export SINGLEM_METAPACKAGE_PATH=${DB}

        # singlem pipe -i <fastq_or_fasta> -p <output.profile.tsv> --taxonomic-profile-krona <output.profile.html>
        #   or
        # singlem pipe -1 <fastq_or_fasta1> -2 <fastq_or_fasta2> -p <output.profile.tsv> --taxonomic-profile-krona <output.profile.html>

        singlem pipe \
            ${true="-1" false='-i' PAIRED} ${sep='-2' READS} \
            --threads ${CPU} \
            -p ${PREFIX}.tsv \
            --taxonomic-profile-krona ${PREFIX}.krona.html
        
        singlem pipe --version > ${PREFIX}.info
    >>>
    output {
        File report_tsv = "${PREFIX}.tsv"
        File full_tsv = "${PREFIX}.full.tsv"
        File krona_html = "${PREFIX}.krona.html"
        File info = "${PREFIX}.info"
    }
    runtime {
        docker: DOCKER
        cpu: CPU
        node: 1
        nwpn: 1
        mem: "45G"
        time: "04:00:00"
    }
    meta {
        author: "Po-E Li, B10, LANL"
        email: "po-e@lanl.gov"
    }
}

task generateSummaryJson {
    Array[Map[String, String]?] TSV_META_JSON
    String PREFIX
    String DOCKER

    command {
        outputTsv2json.py --meta ${write_json(TSV_META_JSON)} > ${PREFIX}.json
    }
    output {
        File summary_json = "${PREFIX}.json"
    }
    runtime {
        docker: DOCKER
        node: 1
        nwpn: 1
        mem: "45G"
        time: "04:00:00"
    }
    meta {
        author: "Po-E Li, B10, LANL"
        email: "po-e@lanl.gov"
    }
}
