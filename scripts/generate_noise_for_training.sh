#!/bin/bash
 
d_cmd=`pwd`/acoustic-simulator/degrade-audio.py # degrade audio command
 
noises=`pwd`/acoustic-simulator/noise-file-list-train.txt # training noises file
spaces=`pwd`/train-spaces
 
train_dir=`pwd`/kaldi-trunk3/egs/wsj/s5/data/train_si284 # clean directory
train_noise_dir=$train_dir/../train_si284_noise # noise directory
wav_file=$train_dir/wav.scp
 
cp -r $train_dir $train_noise_dir
 
[ -f $train_noise_dir/wav_noise.scp ] && rm $train_noise_dir/wav_noise.scp
 
while read p; do
    noise=`shuf -n 1 $noises`
    #space=`shuf -n 1 $spaces`
    snr=$(( $RANDOM % 21 )) # random snr between 0 and 100
    #wet=$(( $RANDOM % 101 )) # random wet between 0 and 100
   
    uid=`echo $p | cut -d' ' -f1`
    wav=`echo $p | cut -d' ' -f2-`
   
    echo "Add noise utterance ..."
    echo "${uid}-noise $wav python $d_cmd -r 16000 -c noise[filter=$noise,snr=$snr] stdin.wav stdout.wav |" >> $train_noise_dir/wav_noise.scp
    echo "$p" >> $train_noise_dir/wav_noise.scp
done < $wav_file
 
echo "generate text.noise.final"
awk '{printf $1"-noise";  for(i=2;i<=NF;i++){printf " %s", $i} printf "\n"}' < $train_noise_dir/text > $train_noise_dir/text.noise
cat $train_noise_dir/text $train_noise_dir/text.noise > $train_noise_dir/text.noise.final

echo "generate utt2spk.noise.final" 
cat $train_noise_dir/utt2spk | sed 's/ /-noise /g' > $train_noise_dir/utt2spk.noise
cat $train_noise_dir/utt2spk $train_noise_dir/utt2spk.noise > $train_noise_dir/utt2spk.noise.final

echo "generate spk2utt.noise.final"
awk '{printf $1;  for(i=2;i<=NF;i++){printf " %s %s-noise", $i, $i} printf "\n"}' < $train_noise_dir/spk2utt > $train_noise_dir/spk2utt.noise.final

cat $train_noise_dir/text.noise.final | sort -u > $train_noise_dir/text
cat $train_noise_dir/utt2spk.noise.final | sort -u > $train_noise_dir/utt2spk
mv $train_noise_dir/spk2utt.noise.final $train_noise_dir/spk2utt
cat $train_noise_dir/wav_noise.scp | sort -u > $train_noise_dir/wav.scp
rm $train_noise_dir/*.noise.final
rm $train_noise_dir/{wav_noise.scp,text.noise,utt2spk.noise}
 
