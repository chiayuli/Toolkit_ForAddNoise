#!/bin/bash
 
d_cmd=`pwd`/acoustic-simulator/degrade-audio.py # degrade audio command
 
noises=`pwd`/acoustic-simulator/noise-file-list-test.txt # testing noises file
#spaces=`pwd`/test-spaces
 
tag=snr012
maxsnr=13

test1_dir=/mount/arbeitsdaten/asr/licu/kaldi-trunk3/egs/wsj/s5_test/data/test_dev93 # clean test directory
test2_dir=/mount/arbeitsdaten/asr/licu/kaldi-trunk3/egs/wsj/s5_test/data/test_eval92 # clean test directory
test1_noise_dir=/mount/arbeitsdaten/asr/licu/kaldi-trunk3/egs/wsj/s5_$tag/data/test_dev93 # noise directory
test2_noise_dir=/mount/arbeitsdaten/asr/licu/kaldi-trunk3/egs/wsj/s5_$tag/data/test_eval92 # noise directory
test1_wav_file=$test1_dir/wav.scp
test1_text_file=$test1_dir/text
test2_wav_file=$test2_dir/wav.scp
test2_text_file=$test2_dir/text


[ -d $test1_noise_dir ] && rm -rf $test1_noise_dir  
[ -d $test2_noise_dir ] && rm -rf $test2_noise_dir  
mkdir -p $test1_noise_dir 
mkdir -p $test2_noise_dir 

echo "generate $test1_noise_dir/wav.scp"
while read p; do
    noise=`shuf -n 1 $noises`
    snr=$(( $RANDOM % $maxsnr )) # random snr between 0 and 20
   
    uid=`echo $p | cut -d' ' -f1`
    wav=`echo $p | cut -d' ' -f2-`
   
    echo "$p" >> $test1_noise_dir/wav.scp
    echo "${uid}-noise $wav python $d_cmd -r 16000 -c noise[filter=$noise,snr=$snr] stdin.wav stdout.wav |" >> $test1_noise_dir/wav.scp
done < $test1_wav_file

echo "generate $test1_noise_dir/text"
cat $test1_text_file | awk '{for(i=1;i<=NF;i++){printf "%s ",$i};printf "\n";printf "%s-noise ",$1;for(i=2;i<=NF;i++){printf "%s ",$i};printf "\n"}' > $test1_noise_dir/text

echo "generate $test1_noise_dir/utt2spk" 
less -c $test1_noise_dir/wav.scp | awk '{spk=substr($1,1,3);printf("%s %s\n", $1, spk)}' > $test1_noise_dir/utt2spk

echo "generate $test1_noise_dir/spk2utt"
cd /mount/arbeitsdaten/asr/licu/kaldi-trunk3/egs/wsj/s5_$tag/
sort -k 2 $test1_noise_dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $test1_noise_dir/spk2utt 

x=test_dev93
steps/make_mfcc.sh --nj 20 data/$x || exit 1;
steps/compute_cmvn_stats.sh data/$x || exit 1;


utils/validate_data_dir.sh $test1_noise_dir

cd /mount/arbeitsdaten/asr/licu/Toolkit_very_important
echo "generate $test2_noise_dir/wav.scp"
while read p; do
    noise=`shuf -n 1 $noises`
    snr=$(( $RANDOM % $maxsnr )) # random snr between 0 and 20
   
    uid=`echo $p | cut -d' ' -f1`
    wav=`echo $p | cut -d' ' -f2-`
   
    echo "$p" >> $test2_noise_dir/wav.scp
    echo "${uid}-noise $wav python $d_cmd -r 16000 -c noise[filter=$noise,snr=$snr] stdin.wav stdout.wav |" >> $test2_noise_dir/wav.scp
done < $test2_wav_file

echo "generate $test2_noise_dir/text"
cat $test2_text_file | awk '{for(i=1;i<=NF;i++){printf "%s ",$i};printf "\n";printf "%s-noise ",$1;for(i=2;i<=NF;i++){printf "%s ",$i};printf "\n"}' > $test2_noise_dir/text

echo "generate $test2_noise_dir/utt2spk" 
less -c $test2_noise_dir/wav.scp | awk '{spk=substr($1,1,3);printf("%s %s\n", $1, spk)}' > $test2_noise_dir/utt2spk

echo "generate $test2_noise_dir/spk2utt"
cd /mount/arbeitsdaten/asr/licu/kaldi-trunk3/egs/wsj/s5_$tag/
sort -k 2 $test2_noise_dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $test2_noise_dir/spk2utt 

x=test_eval92
steps/make_mfcc.sh --nj 20 data/$x || exit 1;
steps/compute_cmvn_stats.sh data/$x || exit 1;


utils/validate_data_dir.sh $test2_noise_dir

echo "Finish!"

