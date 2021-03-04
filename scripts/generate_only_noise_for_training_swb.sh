#!/bin/bash
 
d_cmd=`pwd`/acoustic-simulator/degrade-audio.py # degrade audio command
 
noises=`pwd`/acoustic-simulator/noise-file-list-test.txt # training noises file
#spaces=`pwd`/train-spaces
 
test_dir=`pwd`/kaldi-trunk3/egs/swbd/s5c_test/data/eval2000 # clean directory
#test_dir=`pwd`/kaldi-trunk3/egs/swbd/s5c_test/data/train_dev # clean directory
test_noise_dir=$test_dir/../eval2000_only_noise # noise directory
#test_noise_dir=$test_dir/../train_dev_noise # noise directory
wav_file=$test_dir/wav.scp

[ ! -d $test_noise_dir ] && mkdir $test_noise_dir
cp -r $test_dir/* $test_noise_dir/
 
rm $test_noise_dir/{wav.scp,feats.scp,cmvn.scp,utt2spk,spk2utt}
mv $test_noise_dir/text $test_noise_dir/text.old
mv $test_noise_dir/segments $test_noise_dir/segments.old
mv $test_noise_dir/reco2file_and_channel $test_noise_dir/reco2file_and_channel.old

while read p; do
    noise=`shuf -n 1 $noises`
    snr=$(( $RANDOM % 21 )) # random snr between 0 and 20
   
    uid=`echo $p | cut -d' ' -f1`
    wav=`echo $p | cut -d' ' -f2-`
   
    echo "Add noise utterance ..."
    echo "${uid} $wav python $d_cmd -r 8000 -c noise[filter=$noise,snr=$snr] stdin.wav stdout.wav |" >> $test_noise_dir/wav.scp
done < $wav_file

echo "generate text"
#cat $test_noise_dir/text.old | awk '{printf "%s-noise ",$1;for(i=2;i<=NF;i++){printf "%s ",$i};printf "\n"}' > $test_noise_dir/text 

#echo "generate segments in $test_noise_dir"
#cat $test_noise_dir/segments.old | awk '{printf "%s-noise ",$1;printf "%s-noise ",$2;for(i=3;i<=NF;i++){printf "%s ",$i};printf "\n"}' > $test_noise_dir/segments

#echo "generate reco2file_and_channel"
#cat $test_noise_dir/reco2file_and_channel.old | awk '{printf "%s-noise ",$1;for(i=2;i<=NF;i++){printf "%s ",$i};printf "\n"}' > $test_noise_dir/reco2file_and_channel

#echo "generate utt2spk in $test_noise_dir" 
# This is for eval2000
#awk '{spk=substr($1,1,9); print $1 " " spk}' $test_noise_dir/segments > $test_noise_dir/utt2spk
# This is for train_dev
#awk '{spk=substr($1,1,8); print $1 " " spk}' $test_noise_dir/segments > $test_noise_dir/utt2spk

#echo "generate spk2utt in $test_noise_dir"
#sort -k 2 $test_noise_dir/utt2spk | $test_dir/../../utils/utt2spk_to_spk2utt.pl > $test_noise_dir/spk2utt

#echo "Finish!"

## validate the data in order to make MFCC
#cd $test_noise_dir/../../
#utils/validate_data_dir.sh --no-feats $test_noise_dir
