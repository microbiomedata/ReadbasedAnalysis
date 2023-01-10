task profilerGottcha2 {
    Array[File] READS
    String DB
    String PREFIX
    String? RELABD_COL = "ROLLUP_DOC"
    String DOCKER
    Int? CPU = 4

    command <<<
        set -euo pipefail

        gottcha2.py -r ${RELABD_COL} \
                    -i ${sep=' ' READS} \
                    -t ${CPU} \
                    -o . \
                    -p ${PREFIX} \
                    --database ${DB}
        
        grep "^species" ${PREFIX}.tsv | ktImportTaxonomy -t 3 -m 9 -o ${PREFIX}.krona.html - || true
    >>>
    output {
        File report_tsv = "${PREFIX}.tsv"
        File full_tsv = "${PREFIX}.full.tsv"
        File krona_html = "${PREFIX}.krona.html"
    }
    runtime {
        docker: DOCKER
        cpu: CPU
        node: 1
        nwpn: 1
        memory: "45G"
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

        centrifuge -x ${DB} \
                   -p ${CPU} \
                   -U ${sep=',' READS} \
                   -S ${PREFIX}.classification.tsv \
                   --report-file ${PREFIX}.report.tsv
        
        ktImportTaxonomy -m 5 -t 2 -o ${PREFIX}.krona.html ${PREFIX}.report.tsv
    >>>
    output {
      File classification_tsv="${PREFIX}.classification.tsv"
      File report_tsv="${PREFIX}.report.tsv"
      File krona_html="${PREFIX}.krona.html"
    }
    runtime {
        docker: DOCKER
        cpu: CPU
        node: 1
        nwpn: 1
        memory: "45G"
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
        
        kraken2 ${true="--paired" false='' PAIRED} \
                --threads ${CPU} \
                --db ${DB} \
                --output ${PREFIX}.classification.tsv \
                --report ${PREFIX}.report.tsv \
                ${sep=' ' READS}

        ktImportTaxonomy -m 3 -t 5 -o ${PREFIX}.krona.html ${PREFIX}.report.tsv
    >>>
    output {
      File classification_tsv = "${PREFIX}.classification.tsv"
      File report_tsv = "${PREFIX}.report.tsv"
      File krona_html = "${PREFIX}.krona.html"
    }
    runtime {
        docker: DOCKER
        cpu: CPU
        node: 1
        nwpn: 1
        memory: "45G"
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
        memory: "45G"
        time: "04:00:00"
    }
    meta {
        author: "Po-E Li, B10, LANL"
        email: "po-e@lanl.gov"
    }
}

task stage {
   String container
   String target="raw.fastq.gz"
   String input_file

   command <<<
       set -e
       if [ $( echo ${input_file}|egrep -c "https*:") -gt 0 ] ; then
           wget ${input_file} -O ${target}
       else
           ln ${input_file} ${target} || cp ${input_file} ${target}
       fi
       # Capture the start time
       date --iso-8601=seconds > start.txt

   >>>

   output{
      File read = "${target}"
      String start = read_string("start.txt")
   }
   runtime {
     memory: "1 GiB"
     cpu:  2
     maxRetries: 1
     docker: container
   }
}
