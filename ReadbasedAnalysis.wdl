import "ReadbasedAnalysisTasks.wdl" as tasks

workflow ReadbasedAnalysis {
    Map[String, Boolean] enabled_tools
    Map[String, String] db
    Array[File] reads
    Int cpu
    String prefix
    String? outdir
    Boolean? paired = false
    String? docker = "microbiomedata/nmdc_taxa_profilers:1.0.4"

    if (enabled_tools["gottcha2"] == true) {
        call tasks.profilerGottcha2 {
            input: READS = reads,
                   DB = db["gottcha2"],
                   PREFIX = prefix,
                   CPU = cpu,
                   DOCKER = docker
        }
    }

    if (enabled_tools["kraken2"] == true) {
        call tasks.profilerKraken2 {
            input: READS = reads,
                   PAIRED = paired,
                   DB = db["kraken2"],
                   PREFIX = prefix,
                   CPU = cpu,
                   DOCKER = docker
        }
    }

    if (enabled_tools["centrifuge"] == true) {
        call tasks.profilerCentrifuge {
            input: READS = reads,
                   DB = db["centrifuge"],
                   PREFIX = prefix,
                   CPU = cpu,
                   DOCKER = docker
        }
    }

    if (enabled_tools["singlem"] == true) {
        call tasks.profilerSinglem {
            input: READS = reads,
                   DB = db["singlem"],
                   PREFIX = prefix,
                   CPU = cpu,
                   DOCKER = docker
        }
    }

#    call tasks.generateSummaryJson {
#        input: TSV_META_JSON = [profilerGottcha2.results, profilerCentrifuge.results, profilerKraken2.results],
#               PREFIX = prefix,
#               OUTPATH = outdir,
#               DOCKER = docker
#    }

    if (defined(outdir)){
        call make_outputs {
            input: gottcha2_report_tsv = profilerGottcha2.report_tsv,
                gottcha2_full_tsv = profilerGottcha2.full_tsv,
                gottcha2_krona_html = profilerGottcha2.krona_html,
                centrifuge_classification_tsv = profilerCentrifuge.classification_tsv,
                centrifuge_report_tsv = profilerCentrifuge.report_tsv,
                centrifuge_krona_html = profilerCentrifuge.krona_html,
                kraken2_classification_tsv = profilerKraken2.classification_tsv,
                kraken2_report_tsv = profilerKraken2.report_tsv,
                kraken2_krona_html = profilerKraken2.krona_html,
                outdir = outdir,
                container = docker
        }

        call make_info_file {
            input: enabled_tools = enabled_tools,
                db = db,
                docker = docker,
                gottcha2_info = profilerGottcha2.info,
                gottcha2_report_tsv = profilerGottcha2.report_tsv,
                gottcha2_info = profilerGottcha2.info,
                centrifuge_report_tsv = profilerCentrifuge.report_tsv,
                centrifuge_info = profilerCentrifuge.info,
                kraken2_report_tsv = profilerKraken2.report_tsv,
                kraken2_info = profilerKraken2.info,
                singlem_report_tsv = profilerSinglem.report_tsv,
                singlem_info = profilerSinglem.info,
                outdir = outdir
        }
    }

    output {
        File? gottcha2_report_tsv = profilerGottcha2.report_tsv
        File? gottcha2_full_tsv = profilerGottcha2.full_tsv
        File? gottcha2_krona_html = profilerGottcha2.krona_html
        File? centrifuge_classification_tsv = profilerCentrifuge.classification_tsv
        File? centrifuge_report_tsv = profilerCentrifuge.report_tsv
        File? centrifuge_krona_html = profilerCentrifuge.krona_html
        File? kraken2_classification_tsv = profilerKraken2.classification_tsv
        File? kraken2_report_tsv = profilerKraken2.report_tsv
        File? kraken2_krona_html = profilerKraken2.krona_html
        File? singlem_report_tsv = profilerSinglem.report_tsv,
        File? singlem_info = profilerSinglem.info,
#        File summary_json = generateSummaryJson.summary_json
        File? info_file = make_info_file.profiler_info
        String? info = make_info_file.profiler_info_text
    }

    meta {
        author: "Po-E Li, B10, LANL"
        email: "po-e@lanl.gov"
        version: "1.0.4"
    }
}

task make_outputs{
    String outdir
    File? gottcha2_report_tsv
    File? gottcha2_full_tsv
    File? gottcha2_krona_html
    File? centrifuge_classification_tsv
    File? centrifuge_report_tsv
    File? centrifuge_krona_html
    File? kraken2_classification_tsv
    File? kraken2_report_tsv
    File? kraken2_krona_html
    String container

    command<<<
        mkdir -p ${outdir}/gottcha2
        cp ${gottcha2_report_tsv} ${gottcha2_full_tsv} ${gottcha2_krona_html} \
           ${outdir}/gottcha2
        mkdir -p ${outdir}/centrifuge
        cp ${centrifuge_classification_tsv} ${centrifuge_report_tsv} ${centrifuge_krona_html} \
           ${outdir}/centrifuge
        mkdir -p ${outdir}/kraken2
        cp ${kraken2_classification_tsv} ${kraken2_report_tsv} ${kraken2_krona_html} \
           ${outdir}/kraken2
    >>>
    runtime {
        docker: container
        memory: "1 GiB"
        cpu:  1
    }
    output{
        Array[String] fastq_files = glob("${outdir}/*.fastq*")
    }
}

task make_info_file {
    Map[String, Boolean] enabled_tools
    Map[String, String] db
    String? docker
    File? gottcha2_report_tsv
    File? gottcha2_info
    File? centrifuge_report_tsv
    File? centrifuge_info
    File? kraken2_report_tsv
    File? kraken2_info
    File? singlem_report_tsv
    File? singlem_info
    String outdir
    String info_filename = "profiler.info"

    command <<<
        set -euo pipefail

        # generate output info file
        mkdir -p ${outdir}
        
        info_text="Taxonomy profiling tools and databases used: "
        echo $info_text > ${outdir}/${info_filename}

        if [[ ${enabled_tools['kraken2']} == true ]]
        then
            software_ver=`cat ${kraken2_info}`
            #db_ver=`echo "${db['kraken2']}" | rev | cut -d'/' -f 1 | rev`
            db_ver=`cat ${db['kraken2']}/db_ver.info`
            info_text="Kraken2 v$software_ver (database version: $db_ver)"
            echo $info_text >> ${outdir}/${info_filename}
        fi

        if [[ ${enabled_tools['centrifuge']} == true ]]
        then
            software_ver=`cat ${centrifuge_info}`
            db_ver=`cat $(dirname ${db['centrifuge']})/db_ver.info`
            info_text="Centrifuge v$software_ver (database version: $db_ver)"
            echo $info_text >> ${outdir}/${info_filename}
        fi

        if [[ ${enabled_tools['gottcha2']} == true ]]
        then
            software_ver=`cat ${gottcha2_info}`
            db_ver=`cat ${db['gottcha2']}/db_ver.info`
            info_text="Gottcha2 v$software_ver (database version: $db_ver)"
            echo $info_text >> ${outdir}/${info_filename}
        fi

        if [[ ${enabled_tools['singlem']} == true ]]
        then
            software_ver=`cat ${singlem_info}`
            db_ver=`cat ${db['singlem']}/db_ver.info`
            info_text="SingleM v$software_ver (database version: $db_ver)"
            echo $info_text >> ${outdir}/${info_filename}
        fi
    >>>

    output {
        File profiler_info = "${outdir}/${info_filename}"
        String profiler_info_text = read_string("${outdir}/${info_filename}")
    }
    runtime {
        memory: "2G"
        cpu:  1
        maxRetries: 1
    }
}