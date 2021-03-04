#!/bin/bash
 
d_cmd=`pwd`/acoustic-simulator/degrade-audio.py # degrade audio command
 
noises=`pwd`/acoustic-simulator/noise-file-list-train.txt # training noises file
#spaces=`pwd`/train-spaces
 
train_dir=`pwd`/kaldi-trunk3/egs/swbd/s5c_test/data/train_nodup # clean directory
train_noise_dir=$train_dir/../train_nodup_noise # noise directory
wav_file=$train_dir/wav.scp

[ ! -d $train_noise_dir ] && mkdir $train_noise_dir 
cp -r $train_dir/* $train_noise_dir/*
 
[ -f $train_noise_dir/wav.scp ] && rm $train_noise_dir/wav.scp
rm $train_noise_dir/{wav.scp,feats.scp,cmvn.scp,utt2spk,spk2utt}
mv $train_noise_dir/text $train_noise_dir/text.old
mv $train_noise_dir/segments $train_noise_dir/segments.old
mv $train_noise_dir/reco2file_and_channel $train_noise_dir/reco2file_and_channel.old

while read p; do
    noise=`shuf -n 1 $noises`
    snr=$(( $RANDOM % 21 )) # random snr between 0 and 20
   
    uid=`echo $p | cut -d' ' -f1`
    wav=`echo $p | cut -d' ' -f2-`
   
    echo "Add noise utterance ..."
    echo "$p" >> $train_noise_dir/wav.scp
    echo "${uid}-noise $wav python $d_cmd -r 8000 -c noise[filter=$noise,snr=$snr] stdin.wav stdout.wav |" >> $train_noise_dir/wav.scp
done < $wav_file

echo "generate text"
cat $train_noise_dir/text.old | awk '{for(i=1;i<=NF;i++){printf "%s ",$i};printf "\n";printf "%s-noise ",$1;for(i=2;i<=NF;i++){printf "%s ",$i};printf "\n"}' > $train_noise_dir/text

echo "generate segments in $train_noise_dir"
cat $train_noise_dir/segments.old | awk '{for(i=1;i<=NF;i++){printf "%s ",$i};printf "\n";printf "%s-noise ",$1;printf "%s-noise ",$2;for(i=3;i<=NF;i++){printf "%s ",$i};printf "\n"}' > $train_noise_dir/segments

echo "generate reco2file_and_channel"
cat $train_noise_dir/reco2file_and_channel.old | awk '{for(i=1;i<=NF;i++){printf "%s ",$i};printf "\n";printf "%s-noise ",$1;for(i=2;i<=NF;i++){printf "%s ",$i};printf "\n"}' > $train_noise_dir/reco2file_and_channel

echo "generate utt2spk in $train_noise_dir" 
awk '{spk=substr($1,3,6); print $1 " " spk}' $train_noise_dir/segments > $train_noise_dir/utt2spk


echo "generate spk2utt in $train_noise_dir"
sort -k 2 $train_noise_dir/utt2spk | $train_dir/../../utils/utt2spk_to_spk2utt.pl > $train_noise_dir/spk2utt 

echo "Finish!"

## validate the data in order to make MFCC
#cd $train_noise_dir/../../
#utils/validate_data_dir.sh --no-feats $train_noise_dir
