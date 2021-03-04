#!/bin/bash
set -e
 
d_cmd=`pwd`/acoustic-simulator/degrade-audio.py # degrade audio command
 
noises=`pwd`/acoustic-simulator/noise-file-list-train.txt # training noises file
#spaces=`pwd`/train-spaces
 
tag=snr012
maxsnr=13

## clean directory
train_dir=/mount/arbeitsdaten/asr/licu/kaldi-trunk3/egs/rm/s5/data/train
test_dir=/mount/arbeitsdaten/asr/licu/kaldi-trunk3/egs/rm/s5/data/test 
wav_file=$train_dir/wav.scp
text_file=$train_dir/text
test_wav_file=$test_dir/wav.scp
test_text_file=$test_dir/text

train_noise_dir=/mount/arbeitsdaten/asr/licu/kaldi-trunk3/egs/rm/s5_$tag/data/train # noise directory
test_noise_dir=/mount/arbeitsdaten/asr/licu/kaldi-trunk3/egs/rm/s5_$tag/data/test # noise directory

[ ! -d $train_noise_dir ] && mkdir -p $train_noise_dir 
[ ! -d $test_noise_dir ] && mkdir -p $test_noise_dir 

ln -s $train_dir/../../steps $train_noise_dir/../../
ln -s $train_dir/../../utils $train_noise_dir/../../
ln -s $train_dir/../../local $train_noise_dir/../../
cp -a $train_dir/../../conf $train_noise_dir/../../

echo "generate $train_noise_dir/wav.scp"
while read p; do
    noise=`shuf -n 1 $noises`
    snr=$(( $RANDOM % $maxsnr )) # random snr between 0 and 20
   
    uid=`echo $p | cut -d' ' -f1`
    wav=`echo $p | cut -d' ' -f2-`
   
    #echo "Add noise utterance ..."
    echo "$p" >> $train_noise_dir/wav.scp
    echo "${uid}-noise $wav python $d_cmd -r 16000 -c noise[filter=$noise,snr=$snr] stdin.wav stdout.wav |" >> $train_noise_dir/wav.scp
done < $wav_file

echo "generate $train_noise_dir/text"
cat $train_dir/text | awk '{for(i=1;i<=NF;i++){printf "%s ",$i};printf "\n";printf "%s-noise ",$1;for(i=2;i<=NF;i++){printf "%s ",$i};printf "\n"}' > $train_noise_dir/text

echo "generate $train_noise_dir/utt2spk" 
less -c $train_noise_dir/wav.scp | awk '{spk=substr($1,1,4);printf("%s %s\n", $1, spk)}' > $train_noise_dir/utt2spk

echo "generate $train_noise_dir/spk2utt"
cd $train_noise_dir/../../ 
sort -k 2 $train_noise_dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $train_noise_dir/spk2utt 

utils/validate_data_dir.sh --no-feats $train_noise_dir

cd /mount/arbeitsdaten/asr/licu/Toolkit_very_important/ 

echo "generate $test_noise_dir/wav.scp"
while read p; do
    noise=`shuf -n 1 $noises`
    snr=$(( $RANDOM % $maxsnr )) # random snr between 0 and 20
   
    uid=`echo $p | cut -d' ' -f1`
    wav=`echo $p | cut -d' ' -f2-`
   
    #echo "Add noise utterance ..."
    echo "$p" >> $test_noise_dir/wav.scp
    echo "${uid}-noise $wav python $d_cmd -r 16000 -c noise[filter=$noise,snr=$snr] stdin.wav stdout.wav |" >> $test_noise_dir/wav.scp
done < $test_wav_file

echo "generate $test_noise_dir/text"
cat $test_text_file | awk '{for(i=1;i<=NF;i++){printf "%s ",$i};printf "\n";printf "%s-noise ",$1;for(i=2;i<=NF;i++){printf "%s ",$i};printf "\n"}' > $test_noise_dir/text

echo "generate $test_noise_dir/utt2spk" 
less -c $test_noise_dir/wav.scp | awk '{spk=substr($1,1,4);printf("%s %s\n", $1, spk)}' > $test_noise_dir/utt2spk

echo "generate $test_noise_dir/spk2utt"
cd $train_noise_dir/../../ 
sort -k 2 $test_noise_dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $test_noise_dir/spk2utt 

utils/validate_data_dir.sh --no-feats $test_noise_dir

echo "Finish!"

