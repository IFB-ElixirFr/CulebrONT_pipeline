#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from pathlib import Path
from pprint import pprint as pp
from snakemake.logging import logger
# load own functions
from AdditionalScripts.tools import CulebrONT, get_last_version, get_version

# GLOBAL VARIABLES
# recovery basedir where culebront was installed
basedir = Path(workflow.snakefile).parent.as_posix()
CULEBRONT_PATH = Path(workflow.snakefile).parent

logo = CULEBRONT_PATH.joinpath('docs/source/_images/culebront_logo.png').as_posix()

version_CulebrONT = get_version(basedir)

logger.info(f"""
    Welcome to CulebrONT  !
    Created on November 2019
    version: {version_CulebrONT}
    @author: Julie Orjuela (IRD), Aurore Comte (IRD), Sebastien Ravel (CIRAD), Florian Charriat (CIRAD), Bao Tram Vi (IRD), François Sabot (IRD) and Sebastien Cunnac (IRD)
    @email: julie.orjuela@ird.fr, aurore@comte.ird.fr

    #     .-+.
    #   `odNNh
    #   +NNd:
    #  .Nh.   ---:`
    #  -Nm`  ````./
    #   oNm/ ```-o-
    #    .yNmo/+/.     .oooooo.               oooo             .o8                  .oooooo.   ooooo      ooo ooooooooooooo
    #    `-+ydNmo.    d8P'  `Y8b              `888            "888                 d8P'  `Y8b  `888b.     `8' 8'   888   `8
    #  `/s+../oNNN:  888          oooo  oooo   888   .ooooo.   888oooo.  oooo d8b 888      888  8 `88b.    8       888
    #  +s/     `hNm  888          `888  `888   888  d88' `88b  d88' `88b `888""8P 888      888  8   `88b.  8       888
    #  os:  ////hNN` 888           888   888   888  888ooo888  888   888  888     888      888  8     `88b.8       888
    #  -so- .//sNNs  `88b    ooo   888   888   888  888    .o  888   888  888     `88b    d88'  8       `888       888
    #   `/oo:.yNd/    `Y8bood8P'   `V88V"V8P' o888o `Y8bod8P'  `Y8bod8P' d888b     `Y8bood8P'  o8o        `8      o888o
    #     -yooo+.
    #   `yNs.`-/oo:
    #   dNo` ....+s+
    #   :shmdddhhy+:

    Please cite our github https://github.com/SouthGreenPlatform/CulebrONT_pipeline
    Licencied under CeCill-C (http://www.cecill.info/licences/Licence_CeCILL-C_V1-en.html)
    and GPLv3 Intellectual property belongs to IRD and authors.

    {get_last_version(version_CulebrONT)}
    """)

# pp(workflow.basedir)
culebront = CulebrONT(workflow, config, CULEBRONT_PATH)
tools_config = culebront.tools_config
cluster_config = culebront.cluster_config
#print(culebront.string_to_dag)
# pp(culebront.export_use_yaml)

# print for debug:
#logger.debug(pp(culebront))
#exit()

# Getting paths on usefully variables
output_dir = config['DATA']['OUTPUT']
fastq_dir = config['DATA']['FASTQ']
reference_file = config['DATA']['REF']

# path_snake = workflow.snakefile
# print(f"path_snake: {path_snake}")

################ WILDCARDS  ################
FASTQ, = glob_wildcards(f"{config['DATA']['FASTQ']}{{fastq}}{culebront.fastq_files_ext}")
nb_racon_rounds = culebront.nb_racon_rounds
nb_pilon_rounds = culebront.nb_pilon_rounds

# load some variables from culebront class
add_circular_name = culebront.add_circular_name

#output of Minipolish, -> (input de Tag Circular Minipolish)
TMP = culebront.TMP
#output of Tag Circular Minipolish , -> (input de fixstart)
TCM = culebront.TCM
#output of raven, shasta, flye, circlator , -> (input de tag_circular)
TAG = culebront.TAG

# recovery list of illumina R1 and R2
R1=culebront.R1
R2=culebront.R2

#######################################
# Change workdir to output path
workdir:config["DATA"]["OUTPUT"]
#######################################


def get_threads(rule, default):
    """
    give threads or 'cpus-per-task from cluster_config rule : threads to SGE and cpus-per-task to SLURM
    """
    if rule in cluster_config and 'threads' in cluster_config[rule]:
        return int(cluster_config[rule]['threads'])
    elif rule in cluster_config and 'cpus-per-task' in cluster_config[rule]:
        return int(cluster_config[rule]['cpus-per-task'])
    elif '__default__' in cluster_config and 'cpus-per-task' in cluster_config['__default__']:
        return int(cluster_config['__default__']['cpus-per-task'])
    elif '__default__' in cluster_config and 'threads' in cluster_config['__default__']:
        return int(cluster_config['__default__']['threads'])
    if workflow.global_resources["_cores"]:
        return workflow.global_resources["_cores"]
    return default

def get_fastq(wildcards):
    return f"{fastq_dir}{wildcards.fastq}{culebront.fastq_files_ext}"


def draft_to_circlator(wildcards):
    if 'CANU' in wildcards.assemblers:
        return rules.run_canu.output.fasta
    if 'SMARTDENOVO' in wildcards.assemblers:
        return rules.run_smartdenovo.output.fasta
    else:
        return 'None'

def draft_to_racon(wildcards):
    n = int(wildcards.nb)
    if n == 1:
        if config['CIRCULAR']:
            return f"{output_dir}{{fastq}}/ASSEMBLERS/{{assemblers}}/POLISHING/ROTATE/rotate_{n}/assembly.racon{n}.fasta"
        else:
            return f"{output_dir}{{fastq}}/ASSEMBLERS/{{assemblers}}/ASSEMBLER/assembly{add_circular_name}.fasta"
    elif n > 1:
        if config['CIRCULAR']:
            return f"{output_dir}{{fastq}}/ASSEMBLERS/{{assemblers}}/POLISHING/ROTATE/rotate_{n}/assembly.racon{n}.fasta"
        else:
            return f"{output_dir}{{fastq}}/ASSEMBLERS/{{assemblers}}/POLISHING/RACON/racon_{n-1}/assembly.racon{n-1}.fasta"
    else:
        raise ValueError(f"loop numbers must be 1 or greater: received {n}")

def draft_to_rotate(wildcards):
    n = int(wildcards.nb)
    if n == 1:
        return  f"{output_dir}{{fastq}}/ASSEMBLERS/{{assemblers}}/ASSEMBLER/assemblyCIRCULARISED_circTag.fasta"
    elif n > 1:
        return f"{output_dir}{{fastq}}/ASSEMBLERS/{{assemblers}}/POLISHING/RACON/racon_{n-1}/assembly.racon{n-1}.fasta"
    else:
        raise ValueError(f"loop numbers must be 1 or greater: received {n}")

def draft_to_correction(wildcards):
    if 'MINIASM' == wildcards.assemblers:
        return f"{output_dir}{{fastq}}/ASSEMBLERS/{{assemblers}}/POLISHING/RACON/racon_{nb_racon_rounds}/assembly.racon{nb_racon_rounds}{TCM}.fasta"
    elif config['POLISHING']['RACON']:
        return f"{output_dir}{{fastq}}/ASSEMBLERS/{{assemblers}}/POLISHING/RACON/racon_{nb_racon_rounds}/assembly.racon{nb_racon_rounds}.fasta"
    else:
        return f"{output_dir}{{fastq}}/ASSEMBLERS/{{assemblers}}/ASSEMBLER/assembly{add_circular_name}.fasta"


def draft_to_pilon(wildcards):
    n = int(wildcards.nbp)
    if n == 1:
        return f"{output_dir}{{fastq}}/ASSEMBLERS/{{assemblers}}/CORRECTION/PILON/pilon_1/assembly.pilon1.fasta"
    elif n > 1:
        return f"{output_dir}{{fastq}}/ASSEMBLERS/{{assemblers}}/CORRECTION/PILON/pilon_{n-1}/assembly.pilon{n-1}.fasta"
    else:
        raise ValueError(f"loop numbers for pilon must be 1 or greater: received {n}")

def get_illumina(wildcards):
    r1 = ""
    r2 = ""
    for element1 in culebront.R1 :
        if wildcards.fastq in element1:
            r1=element1
    for element2 in culebront.R2 :
        if wildcards.fastq in element2:
            r2=element2
    return f"{r1} {r2}"

################################ FINAL ####################################
rule final:
    input:
        f"{output_dir}FINAL_REPORT/CulebrONT_report.html"


################################ ASSEMBLY ####################################
include: f"{basedir}/snakefiles/assemblers.snake"

############################### CIRCULARISATION ##############################
include: f"{basedir}/snakefiles/circular.snake"

################################ POLISHING ####################################
include: f"{basedir}/snakefiles/polishers.snake"

################################ CORRECTION ####################################
include: f"{basedir}/snakefiles/correction.snake"

################################ QUALITY ####################################
include: f"{basedir}/snakefiles/quality.snake"

################################ RAPPORT ####################################

rule rule_graph:
    """
    run dag on {rule}
    """
    threads: get_threads('rule_graph', 1)
    input:
        config = f"{output_dir}config_corrected.yaml",
    params:
        tmp = temp(f"{output_dir}FINAL_REPORT/dag.tmp"),
        cmd = culebront.string_to_dag
    output:
        dag = f"{output_dir}FINAL_REPORT/dag.png"
    log:
        output = f"{output_dir}LOGS/Graph.o",
        error = f"{output_dir}LOGS/Graph.e"
    message:
        """
        making dag ...
        {params.cmd} --configfile {input.config} >{params.tmp}
        dot -Tpng {params.tmp}  >{output.dag}
        """
    shell:
        """
        ({params.cmd} --configfile {input.config} >{params.tmp}
        dot -Tpng {params.tmp}  >{output.dag}) 1>{log.output} 2>{log.error}
        """


rule run_report_snakemake:
    """
    run dag on {rule}
    """
    threads: get_threads('run_report_snakemake', 1)
    input:
        conf = str(culebront.path_config),
    output:
        report_snakemake = f"{output_dir}FINAL_REPORT/snake_report.html"
    message:
        """
        making report ...
        snakemake -n {basedir}/Snakefile --configfile {input.conf} --report {output.report_snakemake}
        """
    shell:
        """
        cd {basedir}
        snakemake -s {basedir}/Snakefile --configfile {input.conf} --report {output.report_snakemake}
        """


rule run_flagstats_stats:
    """
    run stat for flagstats
    """
    threads: get_threads('run_stats', 1)
    input:
        summary = expand(rules.run_flagstat.output.txt, fastq='{fastq}', assemblers=culebront.assembly_tools_activated, quality_step=culebront.last_steps_list)
    output:
        stat = f"{output_dir}{{fastq}}/REPORT/{{fastq}}_flagstats.csv",
    params:
        quality_list = culebront.quality_step,
        assembly_list = culebront.assembly_tools_activated,
        out_dir = directory(f"{output_dir}{{fastq}}/"),
    message:
        """
        make stats from flagstats
        """
    script:
        f"{basedir}/reports/get_stats_flagstats.py"


rule run_busco_stats:
    """
    run stat
    """
    threads: get_threads('run_stats', 1)
    input:
        summary = expand(rules.run_busco.output.summary, fastq='{fastq}', assemblers=culebront.assembly_tools_activated, quality_step=culebront.quality_step)
    output:
        stat = f"{output_dir}{{fastq}}/REPORT/{{fastq}}_busco.csv",
    params:
        quality_list = culebront.quality_step,
        assembly_list = culebront.assembly_tools_activated,
        out_dir = directory(f"{output_dir}{{fastq}}/"),
    message:
        """
        make stats
        """
    script:
        f"{basedir}/reports/get_stats_busco.py"


rule run_racon_version:
    """
    launch Racon version
    """
    threads: get_threads('run_racon_version', 1)
    input:
        fastq = get_fastq,
    output:
        version = f"{output_dir}{{fastq}}/REPORT/RACON-version.txt",
    singularity:
        tools_config['SINGULARITY']['TOOLS']
    envmodules:
        tools_config["ENVMODULE"]["RACON"],
        tools_config["ENVMODULE"]["MINIMAP2"]
    shell:
        """
        [ ! -f {output.version} ] &&  [ ! -d versions ] && mkdir -p versions; racon --version > {output.version}
        ln -s -f {output.version} {output_dir}versions/RACON-version.txt
        """


rule run_busco_version:
    """
    busco version
    """
    threads: get_threads('run_busco_version', 1)
    input:
        stats = rules.run_busco_stats.output.stat
    output:
        busco_version = f"{output_dir}{{fastq}}/REPORT/BUSCO-version.txt",
        augustus_version = f"{output_dir}{{fastq}}/REPORT/BUSCO_AUGUSTUS-version.txt",
    message:
        """
        busco version
        """
    singularity:
        tools_config['SINGULARITY']['TOOLS']
    envmodules:
        tools_config["ENVMODULE"]["BUSCO"]
    shell:
        """
        [ ! -f {output.busco_version} ] &&  [ ! -d versions ] && mkdir -p versions; busco --version > {output.busco_version}
        ln -s -f {output.busco_version} {output_dir}versions/BUSCO-version.txt
        [ ! -f {output.augustus_version} ] &&  [ ! -d versions ] && mkdir -p versions; python {CULEBRONT_PATH}/AdditionalScripts/which_version.py "augustus --version" | grep 'AUGUSTUS' > {output.augustus_version}
        ln -s -f {output.augustus_version} {output_dir}versions/BUSCO_AUGUSTUS-version.txt
        """

def get_inputs_benchmark(wildcards):
    dico_benchmark_inputs = {
            "assembly_list": expand(f"{output_dir}{{{{fastq}}}}/BENCHMARK/ASSEMBLER/{{assemblers}}.txt", assemblers=culebront.assembly_tools_activated)
    }
    if culebront.polishing_tools_activated:
        dico_benchmark_inputs["polishers_list"] = expand(f"{output_dir}{{{{fastq}}}}/BENCHMARK/POLISHING/{{assemblers}}_{{polishers}}{{nb}}.txt",
                    assemblers=[ass for ass in culebront.assembly_tools_activated if ass not in ["MINIASM"]],
                    polishers=culebront.polishing_tools_activated,
                    nb = range(1, int(nb_racon_rounds)+1))

    if culebront.correction_tools_activated:
        dico_benchmark_inputs["correction_list"] = expand(f"{output_dir}{{{{fastq}}}}/BENCHMARK/CORRECTION/{{correction}}/{{assemblers}}.txt",
                    assemblers=culebront.assembly_tools_activated,
                    correction=[ass for ass in culebront.correction_tools_activated if ass not in ["PILON"]])
        if "PILON" in culebront.correction_tools_activated:
            dico_benchmark_inputs["correction_list"] = expand(f"{output_dir}{{{{fastq}}}}/BENCHMARK/CORRECTION/PILON/{{assemblers}}_PILON{{nb}}.txt",
                        assemblers=culebront.assembly_tools_activated,
                        correction=['PILON'],
                        nb = range(1, int(nb_pilon_rounds)+1))
    # if culebront.quality_tools_activated:
        # dico_benchmark_inputs["quality_list"] = expand(f"{output_dir}{{{{fastq}}}}/BENCHMARK/POLISHING/{{assemblers}}_{{polishers}}{{nb}}.txt",
                    # assemblers=culebront.assembly_tools_activated,
                    # polishers=culebront.polishing_tools_activated,
                    # nb = range(1, int(nb_racon_rounds)+1))
    # pprint.pprint(dico_benchmark_inputs)
    return dico_benchmark_inputs


rule run_benchmark_time:
    """
    run benchmark
    """
    threads: get_threads('run_benchmark_time', 1)
    input:
        unpack(get_inputs_benchmark)
    output:
        stat_time = f"{output_dir}{{fastq}}/REPORT/{{fastq}}_time.csv",
    params:
        out_dir = f"{output_dir}{{fastq}}",
        sample = f"{{fastq}}",
        dico = get_inputs_benchmark
    message:
        """
        unpacking final dico and benchmark
        """
    script:
        f"{basedir}/reports/get_benchmark.py"

rule run_get_versions:
    """
    recovery soft versions
    """
    threads: get_threads('run_get_versions', 1)
    input:
        assemblers = expand(f"{output_dir}{{fastq}}/ASSEMBLERS/{{assemblers}}/ASSEMBLER/{{assemblers}}-version.txt", fastq = FASTQ, assemblers=culebront.assembly_tools_activated),
        polishers = expand(rules.run_racon_version.output.version, fastq=FASTQ[0]),
        correction = expand(f"{output_dir}{{fastq}}/ASSEMBLERS/{{assemblers}}/CORRECTION/{{correction}}/{{correction}}-version.txt", fastq=FASTQ, assemblers=culebront.assembly_tools_activated, correction=culebront.correction_tools_activated),
        circular = expand(f"{output_dir}{{fastq}}/ASSEMBLERS/{{assemblers}}/ASSEMBLER/CIRCLATOR-version.txt", fastq=FASTQ, assemblers=[ass for ass in culebront.assembly_tools_activated if ass in ["CANU","SMARTDENOVO"] and bool(culebront.config['CIRCULAR'])]),
        quality = expand(f"{output_dir}{{fastq}}/ASSEMBLERS/{{assemblers}}/QUALITY/{{quality_step}}/{{quality}}/{{quality}}-version.txt", fastq=FASTQ, assemblers=culebront.assembly_tools_activated, quality_step=culebront.last_steps_list, quality=[qual for qual in culebront.quality_tools_activated if qual not in ["QUAST", "MAUVE", "BUSCO"]]),
        quast = expand(rules.run_quast.output.version, fastq=FASTQ, quality=[qual for qual in culebront.quality_tools_activated if qual in ["QUAST"]]),
        busco = expand(rules.run_busco_version.output.busco_version, fastq=FASTQ[0]),
        mauve = expand(f"{output_dir}/versions/{{quality}}-version.txt", quality=[qual for qual in culebront.quality_tools_activated if qual in ["MAUVE"]]),
    params:
        dir =f'{output_dir}versions/'
    output:
        csv = f"{output_dir}versions.csv",
    message:
        """
        picking software versions used by CulebrONT
        """
    log:
        output=f"{output_dir}LOGS/GETVERSIONS/get_versions.o",
        error = f"{output_dir}LOGS/GETVERSIONS/get_versions.e"
    script:
        f"{basedir}/reports/get_versions.py"


def output_final(wildcards):
    dico_final = {
        "fasta_list" : expand(rules.preparing_fasta_to_quality.output.renamed, fastq=FASTQ, assemblers=culebront.assembly_tools_activated, quality_step=culebront.quality_step),
        "bench_list" : expand(rules.run_benchmark_time.output.stat_time,fastq=FASTQ),
        "dag" : rules.rule_graph.output.dag,
        "versions" : rules.run_get_versions.output.csv
         # "report_snakemake" : rules.run_report_snakemake.output.report_snakemake,
        }
    if config['QUALITY']['QUAST']:
        dico_final.update({
            "quast_files": expand(rules.run_quast.output.report_file, fastq=FASTQ)
         })
    if config['QUALITY']['BUSCO']:
         dico_final.update({
         "busco_stats": expand(rules.run_busco_stats.output.stat, fastq = FASTQ)
         })
    if config['QUALITY']['BLOBTOOLS']:
        dico_final.update({
            "blob_files": expand(rules.run_blobtools.output.table, fastq=FASTQ, assemblers=culebront.assembly_tools_activated, quality_step=culebront.last_steps_list)
        })
    if config['QUALITY']['ASSEMBLYTICS']:
        dico_final.update({
             "assemblytics_files": expand(rules.run_assemblytics.output.summary, fastq=FASTQ, assemblers=culebront.assembly_tools_activated, quality_step=culebront.last_steps_list)
        })
    if config['QUALITY']['KAT']:
        dico_final.update({
            "kat_files":  expand(rules.run_KAT.output.gcp, fastq=FASTQ, assemblers=culebront.assembly_tools_activated, quality_step=culebront.last_steps_list)
        })
    if config['QUALITY']['FLAGSTATS']:
         dico_final.update({
         "flagstats_stats": expand(rules.run_flagstats_stats.output.stat, fastq = FASTQ)
         })
    if config['MSA']['MAUVE']:
        dico_final.update({
            "mauve_files": expand(f"{output_dir}{{fastq}}/AGGREGATED_QC/MAUVE_ALIGN/candidate_assemblies.xmfa", fastq=FASTQ)
        })
    return dico_final



rule run_report:
    """
    printing  CulebrONT report
    """
    threads: get_threads('run_report', 1)
    input:
        unpack(output_final),
    params:
        samples_list = FASTQ,
        txt_config = culebront.export_use_yaml,
        out_dir_report = directory(f"{output_dir}FINAL_REPORT"),
        quality_tools_list = culebront.quality_tools_activated,
        logo = logo
    output:
        report = f"{output_dir}FINAL_REPORT/CulebrONT_report.html"
    message:
        """
        print final CulebrONT_report ...
        """
    singularity:
        tools_config['SINGULARITY']['REPORT']
    envmodules:
        tools_config['ENVMODULE']['R']
    script:
        f"{basedir}/reports/Report.Rmd"
