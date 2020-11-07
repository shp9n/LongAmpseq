# LongAmpseq
The analysis for "CRISPR/Cas9 gene-editing of HSPCs from SCD patients has unintended consequences". 
The pipeline for illumina based large deletion profiling (LongAmp-seq) and Nano-pore based long-read analysis are stored in the following folders:  

## Repository structure
**Folder: Illumina**  
The scripts for processing LongAmp-seq data.  
+ longamp_bwa_PCR.sh  
Processing raw Illumina data for PCR based library and provide read splitting patterns for grouping and visualization.
+ longamp_bwa_cellline.sh  
Processing raw Illumina data for the reporter cell line and provide read splitting patterns for grouping and visualization.
+ bedfile.py  
Processing read splitting patterns output from bash scripts and provide large deletion patterns and frequency analysis  
+ longampfigures_distribution.py  
Data visualizations.  
  
**Folder: Nanopore**    
The scripts for processing Nanopore data (by Yilei Fu @ Treagen Lab).
The jupyter notebook provides raw sequencing data alignment, large deletion calling, clustering, downstream analysis 
and visualizations.

## Environment set up
We recommend users to utilize virtual environment control tools such as conda to set up python environment.
The current version is on python 3, with the commands as follows for downloading required packages using conda:  
```
conda create -n longamp python=3
conda activate longamp
conda install -c bioconda bwa samtools seqtk bedtools
conda install numpy scikit-learn pandas scipy
conda install -c conda-forge matplotlib
```  

For delly installation, please refer to the original github page: https://github.com/dellytools/delly

After setting up the environment, you can put the scripts into the folder containing the demultiplexed fastqs 
(The standard output fastq of bcl2fastq should end with R1_001.fastq or R2_001.fastq).  

```
git clone https://github.com/baolab-rice/LongAmpseq.git ./
``` 

## LongAmp-seq analysis
+ Raw data processing  
 
For processing raw illumina fastqs (using common cell types that can utilize the reference genome directly)
```
bash longamp_bwa_PCR.sh [chromosome] [start index of long-range PCR] [index of cut site] [index of cut site +1] [end index of long-range PCR] [directory to the reference genome]
```
For example:
```
bash longamp_bwa_PCR.sh chr11 5245453 5248229 5248230 5250918 ~/Desktop/genomes/hg19/hg19.fa
```
And the output in csv format (file name ended with "filtered_2+.csv") should look like:

| Chromosome | Start    | End      | Read ID                                      | Score | Strand |
|------------|----------|----------|----------------------------------------------|-------|--------|
| chr11      | 59136655 | 59136956 | M04808:132:000000000-CTP75:1:2107:19955:2557 | 60    | -      |
| chr11      | 59138619 | 59138657 | M04808:132:000000000-CTP75:1:2107:19955:2557 | 60    | -      |

For reporter cell lines, please use 
```
bash longamp_bwa_cellline.sh GFPBFP 1 1004 1005 9423 GFPBFP_9423bp_NEW_ref_cutsite_1004bp.fa
```

+ Large deletion Profile generating  

The raw data processing section will call the correlated script and run it for you. 
For processing this step by yourselves, users can run the command as below:
```
# for general use
python bedfile.py [the filtered_2+.csv file] [output1: largedel_output.csv] [output2: largedel_group.csv]

# or for using reporter cell line
# Step 1: get the read number that spanning the cut site without large deletion:
echo $(cat [your file end with 30_filtered_1.fastq]|wc -l)/4|bc
# Step 2: run the following command
python bedfile_cellline.py [the filtered_2+.csv file] [output1: largedel_output.csv] [output2: largedel_group.csv] [length of amplicon, default=9423] [The number you got in Step 1]
```

+ Visualization  

The raw data processing section will call the correlated script and run it for you. 
For processing this step by yourselves, users can run the command as below:
```
# for general use
python longampfigures_distribution.py [the largedel_output.csv file] 

# or for using reporter cell line, use the "red_blue_profile_cellline" function instead of the standard function.
```

---------------------------------------

Please contact Yidan Pan (yidan.pan@rice.edu) if you have any questions.