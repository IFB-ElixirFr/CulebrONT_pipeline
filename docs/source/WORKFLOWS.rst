.. contents:: Table of Contents
   :depth: 2
   :backlinks: entry

How to create a workflow
========================

CulebrONT allow you to build a workflow using a simple configuration ``config.yaml`` file. In this file :

* First, provide data paths
* Second, activate tools from assembly to correction.
* Third, activate tools from quality checking of assemblies.
* And last, manage parameters tools.

1. Providing data
------------------

First, indicate the data path in the configuration ``config.yaml`` file:

.. code-block:: YAML

   DATA:
       FASTQ: '/path/to/fastq/directory/'
       REF: '/path/to/referencefile.fasta'
       GENOME_SIZE: '1m'
       FAST5: '/path/to/fast5/directory/'
       ILLUMINA: '/path/to/illumina/directory/'
       OUTPUT: '/path/to/output/directory/'

Find here a summary table with description of each data need to lauch CulebrONT :

.. csv-table::
    :header: "Input", "Description"
    :widths: auto

    "FASTQ", "Every FASTQ file should contain the whole set of reads to be assembled. Each fastq file will be assembled independently."
    "REF","Only one REFERENCE genome file will be used by CulebrONT. This REFERENCE will be used for quality steps (ASSEMBLYTICS, QUAST and MAUVE)"
    "GENOME_SIZE", "Estimated genome size of the assembly can be done on mega (Mb), giga(Gb) or kilobases (Kb). This size is used on some assemblers (CANU) and also on QUAST quality step"
    "FAST5","Nanopolish needs FAST5 files to training steps. Please give the path of FAST5 folder in the *FAST5* DATA parameter. Inside this directory, a subdirectory with the exact same name as the corresponding FASTQ (before the *.fastq.gz*\ ) is requested. For instance, if in the *FASTQ* directory we have *run1.fastq.gz* and *run2.fastq.gz*\ , CulebrONT is expecting the *run1/* and *run2/* subdirectories in the FAST5 main directory"
    "ILLUMINA","Indicate the path to the directory with *Illumina* sequence data (in fastq or fastq.gz format) to perform pilon correction and KAT on quality. Use preferentially paired-end data. All fastq files need to be homogeneous on their extension name. Please use *sample_R1* and *sample_R2* nomenclature."
    "OUTPUT","output *path* directory"

.. warning::

    For FASTQ, naming convention accepted by CulebrONT is *NAME.fastq.gz* or *NAME.fq.gz* or *NAME.fastq* or *NAME.fq*. Preferentially use short names and avoid special characters because report can fail. Avoid to use the long name given directly by sequencer.

    All fastq files have to be homogeneous on their extension and can be compressed or not.

    Reference fasta file need a fasta or fa extension uncompressed.

2. Choose assemblers, polisher and correctors
---------------------------------------------

Activate/deactivate assemblers, polishers and correctors as you wish.
Feel free to activate only assembly, assembly+polishing or assembly+polishing+correction.

.. note::
    If you are working on prokaryote, is recommendated to activate CIRCULAR steps

Example:

.. literalinclude:: ../../config.yaml
    :language: YAML
    :lines: 10-27


3. Choose quality tools
-----------------------
With CulebrONT you can use several quality tools to check assemblies.

* If BUSCO or QUAST are used, every fasta generated on the pipeline will be used with them.

* If BLOBTOOLS, ASSEMBLYTICS, FLAGSTATS and KAT are activated only the last draft generated on the pipeline will be used.

* KAT quality tool can be activate but Illumina reads are mandatory in this case. These reads can be compressed or not.

.. literalinclude:: ../../config.yaml
    :language: YAML
    :lines: 29-38

Alignment of various assemblies **for small genomes (<10-20Mbp)** is also possible by using Mauve.

* If you want to improve alignment with MAUVE on circular molecules is recommended to activate *Fixstart* step.
* Only activate MAUVE if you have more than one sample and more than one quality step.

.. literalinclude:: ../../config.yaml
    :language: YAML
    :lines: 41-43


4. Parameters for some specific tools
--------------------------------------

You can manage tools parameters on the params section on ``config.yaml`` file.

Specifically to ``Racon``:

* Racon can be launch recursively from 1 to 9 rounds. 2 or 3 are recommended.

Specifically to ``Medaka``:

* If 'MEDAKA_TRAIN_WITH_REF' is activated, Medaka launchs training using the reference found in 'DATA/REF' param. Medaka does not take into account other medaka model parameters.

* If 'MEDAKA_TRAIN_WITH_REF' is deactivated, Medaka does not launch training but uses instead the model provided in 'MEDAKA_MODEL_PATH'. Give to CulebrONT path of medaka model *OR* only the model name in order to correct assemblies. This parameter could not be empty.

.. important::
    Medaka models can be downloaded from the medaka repository. You need to install ``git lfs`` (see documentation here https://git-lfs.github.com/) to download largest files before ``git clone https://github.com/nanoporetech/medaka.git\``.

Specifically to ``Pilon``:

* We set java memory into Singularity.culebront_tools to 8G. If you need to allocate more memory it's possible changing this line ``sed -i "s/-Xmx1g/-Xmx8g/g" /usr/local/miniconda/miniconda3/envs/pilon/bin/pilon`` into ``Containers/Singularity.culebront_tools.def`` before singularity building images.

Specifically to ``Busco``:

* If BUSCO is activate, give to CulebrONT the path of busco database *OR* only the database name.This parameter could not be empty.

Specifically to ``Blobtools``:
* nodes and names from ncbi taxdump database can be download from here : https://github.com/DRL/blobtools#download-ncbi-taxdump-and-create-nodesdb

Here you find standard parameters used on CulebrONT. Feel free to adapt it to your requires.

.. literalinclude:: ../../config.yaml
    :language: YAML
    :lines: 46-

.. warning::
    Please check documentation of each tool and make sure that the settings are correct!

.. ############################################################

How to run the workflow
=======================

CulebrONT can be install in a simple machine using a Docker Virual Machine :ref:`Steps for LOCAL installation` but if data are consequent it's recommended to install CulebrONT in a HPC :ref:`Steps for HPC installation`. Please ask to your system administrator for CulebrONT install.

In any case, before run CulebrONT please be sure you have already modified the ``config.yaml`` file as was explained on :ref:`How to create a workflow`. In fact, through snakemake, a pipeline is created using the configuration files you use.

For local or HPC mode, CulebrONT can be run using a typical ``snakemake`` command line (check some examples given in :ref:`Using a standard Snakemake command line (HPC)` section  OR through the ``submit_culebront.sh`` script. A nutshell, ``submit_culebront.sh`` is just assembling a snakemake command line depending on the situation of the user but it can be expense of flexibility. For easy to use, ``submit_culebront.sh`` have four options:

.. code-block:: bash

    -v        : enable verbose mode (default disable)
    -c option : config.yaml file
    -k option : cluster_config.yaml
    -p option : profile path
    -a option : additional snakemake options (--dryrun, --cores ...)

Running in a local machine
--------------------------

If you are on LOCAL mode, give at least the -c option to ``submit_culebront.sh``.

.. code-block:: bash

    # in LOCAL using maximum 8 threads
    submit_culebront.sh -v -c config.yaml -a "--cores 8 "

    # in LOCAL using 6 threads for Canu assembly from the total 8 threads
    submit_culebront.sh -v -c config.yaml -a "--cores 8 --set-threads run_canu=6"
    submit_culebront.sh -v -c config.yaml -a '--cores 8'

.. note::

    Using ``submit_culebront.sh`` you can optionally pass to snakemake more options by using the -a parameter (check it https://snakemake.readthedocs.io/en/stable/executing/cli.html).

Running in a HPC
----------------

If you are on HPC mode, give to ``submit_culebront.sh`` at least the -c option and -p options to the ``submit_culebront.sh`` script. You can use profiles to manage cluster resources. Go to :ref:`3. Snakemake profiles` for details OR ask to your admin system where CulebrONT profile was created.


If you install on HPC with module envs  :ref:`4. Export CulebrONT to PATH`, you can directly use

.. code-block:: bash

    # in HPC using cluster_config.yaml directly from profile
    submit_culebront.sh -c config.yaml --profiles $PROFILE

where `$PROFILE` is declare on module file. If you doesn't use module envs please declare `$PROFILE`

.. code-block:: bash

    # declare profile path directory
    PROFILE=/directory/of/culebront/profile/
    submit_culebront.sh -c config.yaml --profiles $PROFILE


If cluster default resources are not sufficient, you can overwrite ``cluster_config.yaml`` file used by the profile. You can use -k option to overwrite cluster resources.

.. code-block:: bash

    # in HPC mode, overwriting cluster_config.yaml given by user
    submit_culebront.sh -c config.yaml -k cluster_config.yaml --profiles $PROFILE
    # in HPC mode, overwriting cluster_config.yaml given by user and launch a --dryrun
    submit_culebront.sh -c config.yaml -k cluster_config.yaml --profiles $PROFILE -a '--dryrun'

.. note::
    Using ``submit_culebront.sh`` you can optionally pass to snakemake more options by using the -a parameter (check it https://snakemake.readthedocs.io/en/stable/executing/cli.html).

In any case, ``submit_culebront.sh`` launcher can be submitted to SLURM queue using the ``CulebrONT.sbatch``. Don't forget adapt ``CulebrONT.sbatch`` to your scheduler parameter.

.. code-block:: bash

    sbatch CulebrONT.sbatch

Now, take a coffee or tea, and enjoy !!!!!!


Output on CulebrONT
===================

The architecture of CulebrONT output is designed as follows:

.. code-block:: bash

    OUTPUT_CULEBRONT_CIRCULAR/
    ├── SAMPLE-1
    │   ├── AGGREGATED_QC
    │   │   ├── DATA
    │   │   ├── MAUVE_ALIGN
    │   │   └── QUAST_RESULTS
    │   ├── ASSEMBLERS
    │   │   ├── CANU
    │   │   │   ├── ASSEMBLER
    │   │   │   ├── CORRECTION
    │   │   │   ├── FIXSTART
    │   │   │   ├── POLISHING
    │   │   │   └── QUALITY
    │   │   ├── FLYE
    │   │   │   ├── ...
    │   │   ├── MINIASM
    │   │   │   ├── ...
    │   │   ├── RAVEN
    │   │   │   ├── ...
    │   │   ├── SHASTA
    │   │   │   ├── ...
    │   │   └── SMARTDENOVO
    │   │   │   ├── ...
    │   ├── MISC
    │   │   └── FASTQ2FASTA
    │   ├── LOGS
    │   └── REPORT
    └── FINAL_REPORT
    ├── SAMPLE-2 ...


Report
======

CulebrONT generates a useful report containing, foreach fastq, a summary of interesting statistics and versions of tools used. Please discover an |location_link| ... and enjoy !!

.. |location_link| raw:: html

    <a href="https://itrop.ird.fr/culebront_utilities/FINAL_REPORT/CulebrONT_report.html" target="_blank">example</a>


.. important::
    To visualise the report created by CulebrONT, transfer the folder ``FINAL_RESULTS`` on your local computer and open it on a navigator.

