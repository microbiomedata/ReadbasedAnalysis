version 1.0

import "ReadbasedAnalysisTasks.wdl" as tasks
#import "singlem.wdl" as singlem
import "https://code.jgi.doe.gov/gaa/jgi_meta/-/raw/main/jgi_meta_wdl_sets/metagenome_singlem/singlem.wdl" as singlem

workflow ReadbasedAnalysis {
    input {        
        Boolean enabled_tools_gottcha2 = false
        Boolean enabled_tools_kraken2 = false
        Boolean enabled_tools_centrifuge = false
        Boolean enabled_tools_singlem = true
        String db_gottcha2 = "/refdata/gottcha2/RefSeq-r223/gottcha_db.BAVFPt.species.fna"
        String db_kraken2 = "/refdata/kraken2/"
        String db_centrifuge = "/refdata/centrifuge/p_compressed"
        Int    cpu = 8
        File   input_file
        String proj
        String prefix = sub(proj, ":", "_")
        Boolean paired = false
        Boolean long_read = false
        String bbtools_container = "microbiomedata/bbtools:38.96"
        String singlem_container = "wwood/singlem:0.20.2"
        String docker = "ghcr.io/microbiomedata/nmdc-taxa_profilers:1.0.8"
    }

    call stage {
        input:
        container=bbtools_container,
        input_file=input_file,
        paired=paired
    }

    if (enabled_tools_gottcha2 == true) {
        call tasks.profilerGottcha2 {
            input: READS = stage.reads,
                    DB = db_gottcha2,
                    PREFIX = prefix,
                    LONG_READ = long_read,
                    CPU = cpu,
                    DOCKER = docker
        }
    }

    if (enabled_tools_kraken2 == true) {
        call tasks.profilerKraken2 {
            input: READS = stage.reads,
                    PAIRED = paired,
                    DB = db_kraken2,
                    PREFIX = prefix,
                    CPU = cpu,
                    DOCKER = docker
        }
    }

    if (enabled_tools_centrifuge == true) {
        call tasks.profilerCentrifuge {
            input: READS = stage.reads,
                    DB = db_centrifuge,
                    PREFIX = prefix,
                    CPU = cpu,
                    DOCKER = docker
        }
    }

    if (enabled_tools_singlem == true) {
        call singlem.singlem_pipeline {
            input: in_fastq = stage.reads,
                    otu_table = prefix + "_otu_table.csv",
                    n_threads = cpu,
                    long_reads = long_read,
                    container = singlem_container
        }
    }

    call make_info_file {
        input:
            enabled_tools_gottcha2 = enabled_tools_gottcha2,
            enabled_tools_kraken2 = enabled_tools_kraken2,
            enabled_tools_centrifuge = enabled_tools_centrifuge, 
            enabled_tools_singlem = enabled_tools_singlem,
            db_gottcha2 = db_gottcha2,
            db_kraken2 = db_kraken2,
            db_centrifuge = db_centrifuge,
            docker = docker,
            gottcha2_info = profilerGottcha2.info,
            centrifuge_info = profilerCentrifuge.info,
            kraken2_info = profilerKraken2.info,
            singlem_info = singlem_pipeline.stdout
        }

    call finish_reads {
        input:
            proj=proj,
            container="microbiomedata/workflowmeta:1.1.1",
            gottcha2_report_tsv=profilerGottcha2.report_tsv,
            gottcha2_full_tsv=profilerGottcha2.full_tsv,
            gottcha2_krona_html=profilerGottcha2.krona_html,
            centrifuge_classification_tsv=profilerCentrifuge.classification_tsv,
            centrifuge_report_tsv=profilerCentrifuge.report_tsv,
            centrifuge_krona_html=profilerCentrifuge.krona_html,
            kraken2_classification_tsv=profilerKraken2.classification_tsv,
            kraken2_report_tsv=profilerKraken2.report_tsv,
            kraken2_krona_html=profilerKraken2.krona_html,
            singlem_classification_tsv=singlem_pipeline.out_targeted_csv,
            singlem_report_tsv=singlem_pipeline.out_clustered_csv,
            singlem_krona_html=singlem_pipeline.out_clustered_krona,
            prof_info_file=make_info_file.profiler_info
        }

    output {
        File? final_gottcha2_report_tsv = finish_reads.g2_report_tsv
        File? final_gottcha2_full_tsv = finish_reads.g2_full_tsv
        File? final_gottcha2_krona_html = finish_reads.g2_krona_html
        File? final_centrifuge_classification_tsv = finish_reads.cent_classification_tsv
        File? final_centrifuge_report_tsv = finish_reads.cent_report_tsv
        File? final_centrifuge_krona_html = finish_reads.cent_krona_html
        File? final_kraken2_classification_tsv = finish_reads.kr_classification_tsv
        File? final_kraken2_report_tsv = finish_reads.kr_report_tsv
        File? final_kraken2_krona_html = finish_reads.kr_krona_html
        File? final_singlem_classification_tsv = finish_reads.sm_classification_tsv
        File? final_singlem_report_tsv = finish_reads.sm_report_tsv
        File? final_singlem_krona_html = finish_reads.sm_krona_html
        File info_file = finish_reads.rb_info_file
        String info = make_info_file.profiler_info_text
    }

    meta {
        author: "Po-E Li, B10, LANL"
        email: "po-e@lanl.gov"
        version: "1.1.0"
    }
}


task stage {
    input {
        String container
        File   input_file
        Boolean? paired = false
        String memory = "4G"
        String target = "staged.fastq.gz"
        String output1 = "input.left.fastq.gz"
        String output2 = "input.right.fastq.gz"
    }

    command <<<

        set -oeu pipefail
        echo "~{target}"
        if [ $( echo ~{input_file}|egrep -c "https*:") -gt 0 ] ; then
            wget ~{input_file} -O ~{target}
        else
            ln ~{input_file} ~{target} || cp ~{input_file} ~{target}
        fi

        if [ "~{paired}" == "true" ]; then
            reformat.sh -Xmx~{default="10G" memory} in=~{target} out1=~{output1} out2=~{output2} verifypaired=t
        fi

        # Capture the start time
        date --iso-8601=seconds > start.txt

    >>>

    output{
        File read_in = target
        Array[File] reads = if (paired == true) then [output1, output2] else [target]
        String start = read_string("start.txt")
    }
    runtime {
        cpu:  2
        maxRetries: 1
        docker: container
        runtime_minutes: 1400
        memory: "10 GiB"
    }
}

task finish_reads {
    input {
        String container
        String proj
        String prefix=sub(proj, ":", "_")
        File  prof_info_file
        File? gottcha2_report_tsv
        File? gottcha2_full_tsv
        File? gottcha2_krona_html
        File? centrifuge_classification_tsv
        File? centrifuge_report_tsv
        File? centrifuge_krona_html
        File? kraken2_classification_tsv
        File? kraken2_report_tsv
        File? kraken2_krona_html
        File? singlem_classification_tsv
        File? singlem_report_tsv
        File? singlem_krona_html
    }

    command <<<

        set -oeu pipefail
        end=`date --iso-8601=seconds`
        if [[ -f "~{gottcha2_report_tsv}" ]]; then
            if [[ $(head -2 ~{gottcha2_report_tsv}|wc -l) -eq 1 ]] ; then
                echo "Nothing found in gottcha2 for ~{proj} $end" >> ~{prefix}_gottcha2_report.tsv
            else
                ln ~{gottcha2_report_tsv} ~{prefix}_gottcha2_report.tsv || ln -s ~{gottcha2_report_tsv} ~{prefix}_gottcha2_report.tsv
            fi
            ln ~{gottcha2_full_tsv} ~{prefix}_gottcha2_full_tsv || ln -s ~{gottcha2_full_tsv} ~{prefix}_gottcha2_full.tsv
            ln ~{gottcha2_krona_html} ~{prefix}_gottcha2_krona.html || ln -s ~{gottcha2_krona_html} ~{prefix}_gottcha2_krona.html
        fi
        if [[ -f "~{centrifuge_classification_tsv}" ]]; then
            ln ~{centrifuge_classification_tsv} ~{prefix}_centrifuge_classification.tsv || ln -s ~{centrifuge_classification_tsv} ~{prefix}_centrifuge_classification.tsv
            if [[ $(head -2 ~{centrifuge_report_tsv}|wc -l) -eq 1 ]] ; then
                echo "Nothing found in centrifuge for ~{proj} $end" >> ~{prefix}_centrifuge_report.tsv
            else
                ln ~{centrifuge_report_tsv} ~{prefix}_centrifuge_report.tsv || ln -s ~{centrifuge_report_tsv} ~{prefix}_centrifuge_report.tsv
            fi
            ln ~{centrifuge_krona_html} ~{prefix}_centrifuge_krona.html || ln -s ~{centrifuge_krona_html} ~{prefix}_centrifuge_krona.html
        fi
        if [[ -f "~{kraken2_classification_tsv}" ]]; then
            ln ~{kraken2_classification_tsv} ~{prefix}_kraken2_classification.tsv || ln -s ~{kraken2_classification_tsv} ~{prefix}_kraken2_classification.tsv
            if [[ $(head -2 ~{kraken2_report_tsv}|wc -l) -eq 1 ]] ; then
                echo "Nothing found in kraken2 for ~{proj} $end" >> ~{prefix}_kraken2_report.tsv
            else
                ln ~{kraken2_report_tsv} ~{prefix}_kraken2_report.tsv || ln -s ~{kraken2_report_tsv} ~{prefix}_kraken2_report.tsv
            fi
            ln ~{kraken2_krona_html} ~{prefix}_kraken2_krona.html || ln -s ~{kraken2_krona_html} ~{prefix}_kraken2_krona.html
        fi
        if [[ -f "~{singlem_classification_tsv}" ]]; then
            ln ~{singlem_classification_tsv} ~{prefix}_singlem_classification.tsv || ln -s ~{singlem_classification_tsv} ~{prefix}_singlem_classification.tsv
            if [[ $(head -2 ~{singlem_report_tsv}|wc -l) -eq 1 ]] ; then
                echo "Nothing found in singlem for ~{proj} $end" >> ~{prefix}_singlem_report.tsv
            else
                ln ~{singlem_report_tsv} ~{prefix}_singlem_report.tsv || ln -s ~{singlem_report_tsv} ~{prefix}_singlem_report.tsv
            fi
            ln ~{singlem_krona_html} ~{prefix}_singlem_krona.html || ln -s ~{singlem_krona_html} ~{prefix}_singlem_krona.html
        fi

        #info file
        ln ~{prof_info_file} ~{prefix}_profiler.info || ln -s ~{prof_info_file} ~{prefix}_profiler.info

    >>>

    output {
        File? g2_report_tsv="~{prefix}_gottcha2_report.tsv"
        File? g2_full_tsv="~{prefix}_gottcha2_full.tsv"
        File? g2_krona_html="~{prefix}_gottcha2_krona.html"
        File? cent_classification_tsv="~{prefix}_centrifuge_classification.tsv"
        File? cent_report_tsv="~{prefix}_centrifuge_report.tsv"
        File? cent_krona_html="~{prefix}_centrifuge_krona.html"
        File? kr_classification_tsv="~{prefix}_kraken2_classification.tsv"
        File? kr_report_tsv="~{prefix}_kraken2_report.tsv"
        File? kr_krona_html="~{prefix}_kraken2_krona.html"
        File? sm_classification_tsv="~{prefix}_singlem_classification.tsv"
        File? sm_report_tsv="~{prefix}_singlem_report.tsv"
        File? sm_krona_html="~{prefix}_singlem_krona.html"
        File rb_info_file="~{prefix}_profiler.info"
    }

    runtime {
        docker: container
        memory: "1 GiB"
        cpu:  1
        runtime_minutes: 100
    }
}

task make_info_file {
    input {
        Boolean enabled_tools_gottcha2
        Boolean enabled_tools_kraken2
        Boolean enabled_tools_centrifuge
        Boolean enabled_tools_singlem
        String db_gottcha2
        String db_kraken2
        String db_centrifuge
        String docker
        File? gottcha2_info
        File? centrifuge_info
        File? kraken2_info
        File? singlem_info
        String info_filename = "profiler.info"
    }
    command <<<

        set -euo pipefail
        # generate output info file

        info_text="Taxonomy profiling tools and databases used: "
        echo $info_text > ~{info_filename}

                echo $info_text > ~{info_filename}

        if [[ ~{enabled_tools_kraken2} == true ]]
        then
            software_ver=`cat ~{kraken2_info}`
            #db_ver=`echo "~{db_kraken2}" | rev | cut -d'/' -f 1 | rev`
            db_ver=`cat ~{db_kraken2}/db_ver.info`
            info_text="Kraken2 v$software_ver (database version: $db_ver)"
            echo $info_text >> ~{info_filename}
        fi
        echo $info_text > ~{info_filename}

        if [[ ~{enabled_tools_centrifuge} == true ]]
        then
            software_ver=`cat ~{centrifuge_info}`
            db_ver=`cat $(dirname ~{db_centrifuge})/db_ver.info`
            info_text="Centrifuge v$software_ver (database version: $db_ver)"
            echo $info_text >> ~{info_filename}
        fi

        if [[ ~{enabled_tools_gottcha2} == true ]]
        then
            software_ver=`cat ~{gottcha2_info}`
            db_ver=`cat $(dirname ~{db_gottcha2})/db_ver.info`
            info_text="Gottcha2 v$software_ver (database version: $db_ver)"
            echo $info_text >> ~{info_filename}
        fi
        
        if [[ ~{enabled_tools_singlem} == true ]]
        then
            software_ver=`grep -o 'SingleM v[0-9]\+\.[0-9]\+\.[0-9]\+'  ~{singlem_info}|  grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' `
            db_ver=`grep -o '[^/]*\.smpkg\.zb' ~{singlem_info}`
            info_text="SingleM v$software_ver (database version: $db_ver)"
            echo $info_text >> ~{info_filename}
        fi

    >>>

    output {
        File profiler_info = "~{info_filename}"
        String profiler_info_text = read_string("~{info_filename}")
    }
    runtime {
        docker: docker
        memory: "2G"
        cpu:  1
        maxRetries: 1
        runtime_minutes: 100
    }
}
