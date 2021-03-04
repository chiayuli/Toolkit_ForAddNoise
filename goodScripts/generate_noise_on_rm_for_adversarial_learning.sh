#!/bin/bash
set -e
stage=0 
acoustic_tool=/mount/arbeitsdaten/asr/licu/Toolkit_very_important/acoustic-simulator
d_cmd=$acoustic_tool/degrade-audio.py # degrade audio command
noises=$acoustic_tool/noise-file-list-train-labels.txt # training noises file
test_noises=$acoustic_tool/noise-file-list-test-labels.txt # test noises file
#spaces=`pwd`/train-spaces
 
## clean directory
clean_dir=/mount/arbeitsdaten/asr/licu/kaldi-trunk3/egs/rm/s5
train_dir=$clean_dir/data/train
test_dir=$clean_dir/data/test
wav_file=$train_dir/wav.scp
text_file=$train_dir/text
test_wav_file=$test_dir/wav.scp
test_text_file=$test_dir/text

## noise directory
tag=ad3_snr012
noise_dir=/mount/arbeitsdaten/asr/licu/kaldi-trunk3/egs/rm/s5_$tag
train_noise_dir=$noise_dir/data/train # noise directory
test_noise_dir=$noise_dir/data/test # noise directory
test_kn_noise_dir=$noise_dir/data/test_kn # noise directory

if [ $stage -le 0 ]; then
	[ -d $train_noise_dir ] && rm -rf $train_noise_dir
	mkdir -p $train_noise_dir 
	[ -d $test_noise_dir ] && rm -rf $test_noise_dir
	mkdir -p $test_noise_dir 
	[ -d $test_kn_noise_dir ] && rm -rf $test_kn_noise_dir
	mkdir -p $test_kn_noise_dir 

	ln -s $clean_dir/steps $noise_dir
	ln -s $clean_dir/utils $noise_dir
	ln -s $clean_dir/local $noise_dir
	cp -a $clean_dir/conf $noise_dir
	cp -a $clean_dir/data/lang $noise_dir/data
	cp -a $clean_dir/data/local $noise_dir/data
	cp $clean_dir/{path.sh,cmd.sh} $noise_dir

	echo "generate $train_noise_dir/wav.scp"
	while read p; do
    	n=`shuf -n 1 $noises`
    	noise=`echo $n | cut -d' ' -f2`
		noisetype=`echo $n | cut -d' ' -f1`
    	snr=$(($RANDOM % 13))
   
    	uid=`echo $p | cut -d' ' -f1`
    	wav=`echo $p | cut -d' ' -f2-`

    	echo "${uid}-${noisetype} $wav python $d_cmd -r 16000 -c noise[filter=$noise,snr=$snr] stdin.wav stdout.wav |" >> $train_noise_dir/wav.scp
		trans=`grep "${uid}" $train_dir/text | cut -d' ' -f2-`
		echo "${uid}-${noisetype} $trans" >> $train_noise_dir/text
	done < $wav_file
	cat $train_noise_dir/text | sort -u > $train_noise_dir/text.tmp
	mv $train_noise_dir/text.tmp $train_noise_dir/text
 
	echo "generate $train_noise_dir/utt2spk" 
	less -c $train_noise_dir/wav.scp | awk '{spk=substr($1,1,4);printf("%s %s\n", $1, spk)}' | sort -u > $train_noise_dir/utt2spk

	echo "generate $train_noise_dir/spk2utt"
	cd $noise_dir
	sort -k 2 $train_noise_dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $train_noise_dir/spk2utt 

	utils/validate_data_dir.sh --no-feats $train_noise_dir || exit 1;
fi

if [ $stage -le 1 ]; then
	cd /mount/arbeitsdaten/asr/licu/Toolkit_very_important/ 

	echo "generate $test_noise_dir/wav.scp"
	while read p; do
    	n=`shuf -n 1 $test_noises`
    	noise=`echo $n | cut -d' ' -f2`
		noisetype=`echo $n | cut -d' ' -f1`
    	snr=$(($RANDOM % 13))
   
    	uid=`echo $p | cut -d' ' -f1`
    	wav=`echo $p | cut -d' ' -f2-`
   
    	#echo "Add noise utterance ..."
    	echo "${uid}-${noisetype} $wav python $d_cmd -r 16000 -c noise[filter=$noise,snr=$snr] stdin.wav stdout.wav |" >> $test_noise_dir/wav.scp
		trans=`grep "${uid}" $test_dir/text | cut -d' ' -f2-`
		echo "${uid}-${noisetype} $trans" >> $test_noise_dir/text
	done < $test_wav_file
	cat $test_noise_dir/text | sort -u > $test_noise_dir/text.tmp
	mv $test_noise_dir/text.tmp $test_noise_dir/text

	echo "generate $test_noise_dir/utt2spk" 
	less -c $test_noise_dir/wav.scp | awk '{spk=substr($1,1,4);printf("%s %s\n", $1, spk)}' | sort -u > $test_noise_dir/utt2spk

	echo "generate $test_noise_dir/spk2utt"
	cd $noise_dir 
	sort -k 2 $test_noise_dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $test_noise_dir/spk2utt 

	utils/validate_data_dir.sh --no-feats $test_noise_dir || exit 1;
fi

if [ $stage -le 2 ]; then
	cd /mount/arbeitsdaten/asr/licu/Toolkit_very_important/ 

	echo "generate $test_kn_noise_dir/wav.scp"
	while read p; do
    	n=`shuf -n 1 $noises`
    	noise=`echo $n | cut -d' ' -f2`
		noisetype=`echo $n | cut -d' ' -f1`
    	snr=$(($RANDOM % 13))
   
    	uid=`echo $p | cut -d' ' -f1`
    	wav=`echo $p | cut -d' ' -f2-`
   
    	#echo "Add noise utterance ..."
    	echo "${uid}-${noisetype} $wav python $d_cmd -r 16000 -c noise[filter=$noise,snr=$snr] stdin.wav stdout.wav |" >> $test_kn_noise_dir/wav.scp
		trans=`grep "${uid}" $test_dir/text | cut -d' ' -f2-`
		echo "${uid}-${noisetype} $trans" >> $test_kn_noise_dir/text
	done < $test_wav_file
	cat $test_kn_noise_dir/text | sort -u > $test_kn_noise_dir/text.tmp
	mv $test_kn_noise_dir/text.tmp $test_kn_noise_dir/text

	echo "generate $test_kn_noise_dir/utt2spk" 
	less -c $test_kn_noise_dir/wav.scp | awk '{spk=substr($1,1,4);printf("%s %s\n", $1, spk)}' | sort -u > $test_kn_noise_dir/utt2spk

	echo "generate $test_kn_noise_dir/spk2utt"
	cd $noise_dir 
	sort -k 2 $test_kn_noise_dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $test_kn_noise_dir/spk2utt 

	utils/validate_data_dir.sh --no-feats $test_kn_noise_dir || exit 1;
fi

echo "Finish!"

