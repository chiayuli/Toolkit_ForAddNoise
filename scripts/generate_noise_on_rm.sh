#!/bin/bash
set -e
 
d_cmd=`pwd`/acoustic-simulator/degrade-audio.py # degrade audio command
 
noises=`pwd`/noise-file-list-trn-small.txt # training noises file
#spaces=`pwd`/train-spaces
 
tag=ad

## clean directory
train_dir=/mount/arbeitsdaten/asr/licu/kaldi-trunk3/egs/rm/s5/data/train
test_dir=/mount/arbeitsdaten/asr/licu/kaldi-trunk3/egs/rm/s5/data/test
wav_file=$train_dir/wav.scp
text_file=$train_dir/text
test_wav_file=$test_dir/wav.scp
test_text_file=$test_dir/text

train_noise_dir=/mount/arbeitsdaten/asr/licu/kaldi-trunk3/egs/rm/s5_$tag/data/train # noise directory
test_noise_dir=/mount/arbeitsdaten/asr/licu/kaldi-trunk3/egs/rm/s5_$tag/data/test_3_noise # noise directory
if [ 1 == 0 ]; then
[ ! -d $train_noise_dir ] && mkdir -p $train_noise_dir 
[ ! -d $test_noise_dir ] && mkdir -p $test_noise_dir 

ln -s $train_dir/../../steps $train_noise_dir/../../
ln -s $train_dir/../../utils $train_noise_dir/../../
ln -s $train_dir/../../local $train_noise_dir/../../
cp -a $train_dir/../../conf $train_noise_dir/../../
cp $train_dir/text $train_noise_dir/text

echo "generate $train_noise_dir/wav.scp"
while read p; do
    n=`shuf -n 1 $noises`
    noise=`echo $n | cut -d' ' -f3`
	noisetype=`echo $n | cut -d' ' -f1`
    snr=3
   
    uid=`echo $p | cut -d' ' -f1`
    wav=`echo $p | cut -d' ' -f2-`
   
    #echo "Add noise utterance ..."
    echo "$p" >> $train_noise_dir/wav.scp
    echo "${uid}-${noisetype} $wav python $d_cmd -r 16000 -c noise[filter=$noise,snr=$snr] stdin.wav stdout.wav |" >> $train_noise_dir/wav.scp
	trans=`grep "${uid}" $train_dir/text | cut -d' ' -f2-`
	echo "${uid}-${noisetype} $trans" >> $train_noise_dir/text
done < $wav_file
cat $train_noise_dir/text | sort -u > $train_noise_dir/text.tmp
mv $train_noise_dir/text.tmp $train_noise_dir/text
#echo "generate $train_noise_dir/text"
#cat $train_dir/text | awk '{for(i=1;i<=NF;i++){printf "%s ",$i};printf "\n";;printf "%s ",$utt;for(i=2;i<=NF;i++){printf "%s ",$i};printf "\n"}' > $train_noise_dir/text

echo "generate $train_noise_dir/utt2spk" 
less -c $train_noise_dir/wav.scp | awk '{spk=substr($1,1,4);printf("%s %s\n", $1, spk)}' | sort -u > $train_noise_dir/utt2spk

echo "generate $train_noise_dir/spk2utt"
cd $train_noise_dir/../../ 
sort -k 2 $train_noise_dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $train_noise_dir/spk2utt 

utils/validate_data_dir.sh --no-feats $train_noise_dir
fi
if [ 1 == 1 ]; then
cd /mount/arbeitsdaten/asr/licu/Toolkit_very_important/ 
mkdir -p $test_noise_dir
cp $test_dir/text $test_noise_dir/text

echo "generate $test_noise_dir/wav.scp"
while read p; do
    n=`shuf -n 1 $noises`
    noise=`echo $n | cut -d' ' -f3`
	noisetype=`echo $n | cut -d' ' -f1`
    snr=3
   
    uid=`echo $p | cut -d' ' -f1`
    wav=`echo $p | cut -d' ' -f2-`
   
    #echo "Add noise utterance ..."
    echo "$p" >> $test_noise_dir/wav.scp
    echo "${uid}-${noisetype} $wav python $d_cmd -r 16000 -c noise[filter=$noise,snr=$snr] stdin.wav stdout.wav |" >> $test_noise_dir/wav.scp
	trans=`grep "${uid}" $test_dir/text | cut -d' ' -f2-`
	echo "${uid}-${noisetype} $trans" >> $test_noise_dir/text
done < $test_wav_file
cat $test_noise_dir/text | sort -u > $test_noise_dir/text.tmp
mv $test_noise_dir/text.tmp $test_noise_dir/text

echo "generate $test_noise_dir/utt2spk" 
less -c $test_noise_dir/wav.scp | awk '{spk=substr($1,1,4);printf("%s %s\n", $1, spk)}' | sort -u > $test_noise_dir/utt2spk

echo "generate $test_noise_dir/spk2utt"
cd $test_noise_dir/../../ 
sort -k 2 $test_noise_dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $test_noise_dir/spk2utt 

utils/validate_data_dir.sh --no-feats $test_noise_dir

utils/validate_data_dir.sh --no-feats $test_noise_dir
fi

echo "Finish!"

