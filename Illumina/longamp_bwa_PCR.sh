#!/bin/bash

chr_num=${1:-chr11}
pcr_start=${2:-5245453}
cut_site_left=${3:5248229}
cut_site_right=${4:5248230}
pcr_end=${5:-5250918}
ref_genome=${6:-/home/yp11/Desktop/genomes/hg19/hg19.fa}
##########################
# put the script in the same directory as demultiplexed fastq files.

# end with fastq
# start with merging
# use full hg19
# use q30 only for the initial alignment and filtering (same for 0915)
# removed the duplication deduct part

# Yidan Pan @Baolab
##########################

for file in *R1_001.fastq
do
  flash -M600 ${file} ${file/R1/R2} # read length = 300 so we use 300*2 as maximum merged read length
  mv ./out.extendedFrags.fastq ${file/.fastq/_merged.fastq}
done

for file in *merged.fastq
do
  bwa mem -A2 -E1 ${ref_genome} ${file} > ${file/.fastq/.sam}
  samtools view -S -b -q 30 ${file/.fastq/.sam} | samtools sort -o ${file/.fastq/_sorted.bam}
  samtools index ${file/.fastq/_sorted.bam}
  samtools view -b ${file/.fastq/_sorted.bam} ${chr_num}:${pcr_start}-${cut_site_left} > ${file/.fastq/_sortedleft.bam}
  samtools index ${file/.fastq/_sortedleft.bam}
  samtools view -b ${file/.fastq/_sorted.bam} ${chr_num}:${cut_site_right}-${pcr_end} > ${file/.fastq/_sortedright.bam}
  samtools index ${file/.fastq/_sortedright.bam}
  samtools view -F 4 ${file/.fastq/_sortedleft.bam} | cut -f1 | sort -u > ${file/.fastq/_leftID.txt}
  samtools view -F 4 ${file/.fastq/_sortedright.bam} | cut -f1 | sort -u > ${file/.fastq/_rightID.txt}
  comm -12 ${file/.fastq/_leftID.txt} ${file/.fastq/_rightID.txt} > ${file/.fastq/_bothID.txt}
  seqtk subseq ${file} ${file/.fastq/_bothID.txt} > ${file/.fastq/30_filtered.fastq}
#now we have filtered fastq

  bwa mem -A2 -E1 ${ref_genome} ${file/.fastq/30_filtered.fastq} >${file/.fastq/30_filtered.sam}
  samtools view -S -b ${file/.fastq/30_filtered.sam} -o ${file/.fastq/30_filtered.bam}
  samtools sort ${file/.fastq/30_filtered.bam} -o ${file/.fastq/30_filteredsorted.bam}
  bedtools bamtobed -i ${file/.fastq/30_filteredsorted.bam} > ${file/.fastq/30_filtered.bed}
#get the filtered, non-deducted reads

#extract the reads that have supplementary alignments
  samtools view -F 4 ${file/.fastq/30_filtered.bam} | cut -f1 | uniq -d > ${file/.fastq/filtered_2+alignID.txt}
  samtools view -F 4 ${file/.fastq/30_filtered.bam} | cut -f1 | uniq -u > ${file/.fastq/filtered_1alignID.txt}
  seqtk subseq ${file/.fastq/30_filtered.fastq} ${file/.fastq/filtered_2+alignID.txt} > ${file/.fastq/30_filtered_2+.fastq}

  bwa mem -A2 -E1 ${ref_genome} ${file/.fastq/30_filtered_2+.fastq} >${file/.fastq/filtered_2+.sam}
  samtools view -S -b ${file/.fastq/filtered_2+.sam} -o ${file/.fastq/filtered_2+.bam}
  bedtools bamtobed -i ${file/.fastq/filtered_2+.bam} > ${file/.fastq/filtered_2+.bed}

  #convert to csv
  cat ${file/.fastq/filtered_2+.bed} | tr "\\t" "," > ${file/.fastq/filtered_2+.csv}
  python ./bedfile.py ${file/.fastq/filtered_2+.csv} ${file/.fastq/largedel_output.csv} ${file/.fastq/largedel_group.csv}

  # just find the starting position and length of large deletion
  # ignore strand and reads with multiple fragments
  # the format of bed files are more like this:
  # chr11	59136655	59136956	M04808:132:000000000-CTP75:1:2107:19955:2557	60	-
  # chr11	59138619	59138657	M04808:132:000000000-CTP75:1:2107:19955:2557	60	-
  # call a python script for bed file analysis


  # append read numbers into the log file.
  # total aligned events:
  echo ${file/_merged.fastq/} >> log.txt
  echo $(cat ${file/.fastq/30_filtered.fastq}|wc -l)/4|bc >> log.txt
done
