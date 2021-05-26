#!/bin/bash
seqtk="/mctp/users/noshadh/Apps/seqtk/seqtk"
scratch=$(pwd)

function dilute_fastq {
#   $1 is id
#   $2 is t.fastq1 location
#   $3 is t.fastq2 location
#   $4 is n.fastq1 location
#   $5 is n.fastq2 location
#   $6 is write location
#   $7 dilution percent (x% means x part tumor and 1-x part normal) (should be in the form of X1;X2;X3;...;Xn where Xi is the ith dilution)
#   $8 depth percent (what percentage of minimum tumor/normal as total depth)
#   $9 temp folder location

    ## parse the arguments
    echo "[1] PARSING START"
    id=$1
    t_fastq1=$2
    t_fastq2=$3
    n_fastq1=$4
    n_fastq2=$5
    out_fn=$6
    dilutions=$(echo $7 | sed 's/;/\n/g'| sort -nr)
    depth_perc=$8
    temp_fn=$9
    echo "[1] PARSING END"

    # make a folder and unzip the files
    echo "[2] UNZIPING START"
    start=`date +%s`

    mkdir "$temp_fn/tmp"

    zcat $t_fastq1 > "$temp_fn/tmp/$id.t.1.fq"
    fqt1="$temp_fn/tmp/$id.t.1.fq"

    zcat $t_fastq2 > "$temp_fn/tmp/$id.t.2.fq"
    fqt2="$temp_fn/tmp/$id.t.2.fq"

    zcat $n_fastq1 > "$temp_fn/tmp/$id.n.1.fq"
    fqn1="$temp_fn/tmp/$id.n.1.fq"

    zcat $n_fastq2 > "$temp_fn/tmp/$id.n.2.fq"
    fqn2="$temp_fn/tmp/$id.n.2.fq"

    end=`date +%s`
    runtime=$((end-start))
    echo "[2] UNZIPING END, TIME:$runtime seconds"

    ## read normal and tumor depth
    echo "[3] DEPTH READING START"
    depth_t_1=$(echo $(cat $fqt1|wc -l)/4|bc)
    # depth_t_2=$(echo $(cat $fqt2|wc -l)/4|bc)
    depth_n_1=$(echo $(cat $fqn1|wc -l)/4|bc)
    # depth_n_2=$(echo $(cat $fqn2|wc -l)/4|bc)
    echo "[3] DEPTH READING END, N:$depth_n_1, T:$depth_t_1"

    ## select the targeted depth
    # depths="$depth_t_1;$depth_t_2;$depth_n_1;$depth_n_2"
    echo "[4] SELECTING TARGET DEPTH START"
    depths="$depth_t_1;$depth_n_1"
    depth_min=$(echo $depths | sed 's/;/\n/g'| sort -n | head -1)
    depth_target=$(echo "$depth_min*$depth_perc"/1|bc)
    echo "[4] SELECTING TARGET DEPTH END, TARGET:$depth_target"

    ## decide number of reads from normal and tumor  | sample | write
    echo "[5] MAIN PROCESS START"
    mkdir "$out_fn/$id"
    for dil_perc in $dilutions
    do
        echo "[5.0] FOR  DILUTION OF: $dil_perc"
        # determine read numbers
        t_read_num=$(echo "$depth_target*$dil_perc"/1|bc)
        n_read_num=$(echo "$depth_target-$t_read_num"/1|bc)
        echo "[5.1] READ NUMBERS, T:$t_read_num, N:$n_read_num"

        # sample reads
        echo "[5.2] SAMPLING START"
        start_all=`date +%s`
        $seqtk sample -s100 $fqt1 $t_read_num > "$temp_fn/tmp/$id.t.1.tmp.$dil_perc.fq"
        $seqtk sample -s100 $fqt2 $t_read_num > "$temp_fn/tmp/$id.t.2.tmp.$dil_perc.fq"
        $seqtk sample -s100 $fqn1 $n_read_num > "$temp_fn/tmp/$id.n.1.tmp.$dil_perc.fq"
        $seqtk sample -s100 $fqn2 $n_read_num > "$temp_fn/tmp/$id.n.2.tmp.$dil_perc.fq"
        end_all=`date +%s`
        runtime=$((end_all-start_all))
        echo "[5.2] SAMPLING DONE, TIME:$runtime seconds"

        # write into one file
        echo "[5.3] WRITING START"
        cat "$temp_fn/tmp/$id.t.1.tmp.$dil_perc.fq" "$temp_fn/tmp/$id.n.1.tmp.$dil_perc.fq" > "$out_fn/$id/$id.t.1.$dil_perc.fq"
        cat "$temp_fn/tmp/$id.t.2.tmp.$dil_perc.fq" "$temp_fn/tmp/$id.n.2.tmp.$dil_perc.fq" > "$out_fn/$id/$id.t.2.$dil_perc.fq"
        echo "[5.3] WRITING END"
    done
    echo "[5] MAIN PROCESS END"
}

    # echo $id
    # echo $t_fastq1
    # echo $t_fastq2
    # echo $n_fastq1
    # echo $n_fastq2
    # echo $out_fn
    # echo $dilutions
    # echo $depth_perc
    # echo $temp_fn

# id="testingFIRST"
# t_fastq1="/mctp/users/noshadh/data/cin/grants/cin/test/mctp_SI_28322_HH7THBCX3_0_1.fq.gz"
# t_fastq2="/mctp/users/noshadh/data/cin/grants/cin/test/mctp_SI_28322_HH7THBCX3_0_2.fq.gz"
# n_fastq1="/mctp/users/noshadh/data/cin/grants/cin/test/mctp_SI_28323_HH7THBCX3_0_1.fq.gz"
# n_fastq2="/mctp/users/noshadh/data/cin/grants/cin/test/mctp_SI_28323_HH7THBCX3_0_2.fq.gz"
# out_fn="/mctp/users/noshadh/data/cin/grants/cin/test/tmp"
# dilutions="0.1;0.5;0.9"
# depth_perc="0.9"
# temp_fn="/mctp/users/noshadh/data/cin/grants/cin/test/tmp"

# dilute_fastq $id $t_fastq1 $t_fastq2 $n_fastq1 $n_fastq2 $out_fn $dilutions $depth_perc $temp_fn

# ## zcat
# ## seqtk
# echo $depths | sed 's/;/\n/g' | `awk 'BEGIN{min=1000000}{if ($1<0+a) a=$1} END{print a}'

# depth_target=101
# dil_perc=0.53
#         t_read_num=$(echo "$depth_target*$dil_perc"/1|bc)
#         n_read_num=$(echo "$depth_target-$t_read_num"/1|bc)
# depth_t_1=100
# depth_t_2=200
# depth_n_1=150
# depth_n_2=50

# a="0.9;0.7;0.1;0.2;0.5"
# dilutions=$(echo $a | sed 's/;/\n/g'| sort -nr)
#     for dil_perc in $dilutions
#     do
#         echo $dil_perc
#     done


# start=`date +%s`
# # awk '{s++}END{print s/4}' /mctp/users/noshadh/data/cin/grants/cin/test/unziped/mctp_SI_28323_HH7THBCX3_0_1.fq     # 10 seconds
# # echo $(cat /mctp/users/noshadh/data/cin/grants/cin/test/unziped/mctp_SI_28323_HH7THBCX3_0_1.fq|wc -l)/4|bc        # 5 seconds
# # echo $(zcat /mctp/users/noshadh/data/cin/grants/cin/test/mctp_SI_28323_HH7THBCX3_0_1.fq.gz|wc -l)/4|bc             # 53 seconds
# # zcat /mctp/users/noshadh/data/cin/grants/cin/test/mctp_SI_28323_HH7THBCX3_0_1.fq.gz > /mctp/users/noshadh/data/cin/grants/cin/test/unziped/test.fq
# # echo $(cat /mctp/users/noshadh/data/cin/grants/cin/test/unziped/test.fq|wc -l)/4|bc
# cat /mctp/users/noshadh/data/cin/grants/cin/test/unziped/test.fq > /mctp/users/noshadh/data/cin/grants/cin/test/unziped/test2.fq
# end=`date +%s`

# runtime=$((end-start))
# echo $runtime


# zcat my.fastq.gz | echo $((`wc -l`/4))
# #yourfile.fastq  
# echo $(cat yourfile.fastq|wc -l)/4|bc

# #yourfile.fastq.gz
#  echo $(zcat yourfile.fastq.gz|wc -l)/4|bc

