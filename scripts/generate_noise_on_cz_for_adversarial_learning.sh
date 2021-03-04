#!/bin/bash
set -e
stage=0 
acoustic_tool=/mount/arbeitsdaten/asr/licu/Toolkit_very_important/acoustic-simulator
d_cmd=$acoustic_tool/degrade-audio.py # degrade audio command
noises=$acoustic_tool/noise-file-list-trn-5C.txt # training noises file
test_noises=$acoustic_tool/noise-file-list-tst-5C.txt # test noises file
 
## clean directory
clean_dir=/mount/arbeitsdaten/asr/licu/kaldi-trunk3/egs/vystadial_cz/s5b

## noise directory
snr=1
tag=ad3_5dC_snr${snr}
noise_dir=${clean_dir}_$tag

if [ $stage -le 0 ]; then
	train_noise_dir=$noise_dir/data/train # noise directory
	[ -d $train_noise_dir ] && rm -rf $train_noise_dir
	mkdir -p $train_noise_dir 

	ln -s $clean_dir/steps $noise_dir
	ln -s $clean_dir/utils $noise_dir
	ln -s $clean_dir/local $noise_dir
	cp -a $clean_dir/conf $noise_dir
	cp -a $clean_dir/data/lang $noise_dir/data
	cp -a $clean_dir/data/local $noise_dir/data
	cp $clean_dir/{path.sh,cmd.sh} $noise_dir

fi

if [ $stage -le 1 ]; then
	train_dir=$clean_dir/data/train
	wav_file=$train_dir/wav.scp
	echo "generate $train_noise_dir/wav.scp"
	while read p; do
    	n=`shuf -n 1 $noises`
    	noise=`echo $n | cut -d' ' -f2`
		noisetype=`echo $n | cut -d' ' -f1`
    	#snr=$(($RANDOM % 5))
   
    	uid=`echo $p | cut -d' ' -f1`
    	wav=`echo $p | cut -d' ' -f2-`

    	echo "${uid}-${noisetype} python $d_cmd -r 16000 -c noise[filter=$noise,snr=$snr] $wav stdout.wav |" >> $train_noise_dir/wav.scp
		trans=`grep "${uid}" $train_dir/text | cut -d' ' -f2-`
		echo "${uid}-${noisetype} $trans" >> $train_noise_dir/text
		echo "${uid}-${noisetype} ${uid}-${noisetype}" >> $train_noise_dir/utt2spk
	done < $wav_file
	cat $train_noise_dir/text | sort -u > $train_noise_dir/text.tmp
	mv $train_noise_dir/text.tmp $train_noise_dir/text
 
	echo "generate $train_noise_dir/spk2utt"
	cd $noise_dir
	sort -k 2 $train_noise_dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $train_noise_dir/spk2utt 
	utils/fix_data_dir.sh $train_noise_dir
	utils/validate_data_dir.sh --no-feats $train_noise_dir || exit 1;
fi

if [ $stage -le 2 ]; then
	for x in test dev; do
		cd /mount/arbeitsdaten/asr/licu/Toolkit_very_important/ 
		test_dir=$clean_dir/data/${x}
		test_wav_file=$test_dir/wav.scp
 		test_text_file=$test_dir/text
		test_noise_dir=$noise_dir/data/${x}_ukn_noise
		[ -d $test_noise_dir ] && rm -rf $test_noise_dir
		mkdir -p $test_noise_dir 

		echo "generate $test_noise_dir/wav.scp"
		while read p; do
    		n=`shuf -n 1 $test_noises`
    		noise=`echo $n | cut -d' ' -f2`
			noisetype=`echo $n | cut -d' ' -f1`
    		#snr=$(($RANDOM % 5))
   
    		uid=`echo $p | cut -d' ' -f1`
    		wav=`echo $p | cut -d' ' -f2-`
   
    		#echo "Add noise utterance ..."
    		echo "${uid}-${noisetype} python $d_cmd -r 16000 -c noise[filter=$noise,snr=$snr] $wav stdout.wav |" >> $test_noise_dir/wav.scp
			trans=`grep "${uid}" $test_dir/text | cut -d' ' -f2-`
			echo "${uid}-${noisetype} $trans" >> $test_noise_dir/text
			echo "${uid}-${noisetype} ${uid}-${noisetype}" >> $test_noise_dir/utt2spk
		done < $test_wav_file

		cat $test_noise_dir/text | sort -u > $test_noise_dir/text.tmp
		mv $test_noise_dir/text.tmp $test_noise_dir/text

		echo "generate $test_noise_dir/spk2utt"
		cd $noise_dir 
		sort -k 2 $test_noise_dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $test_noise_dir/spk2utt 
		utils/fix_data_dir.sh $test_noise_dir
		utils/validate_data_dir.sh --no-feats $test_noise_dir || exit 1;

	done
fi

if [ $stage -le 3 ]; then
	for x in test dev; do
		cd /mount/arbeitsdaten/asr/licu/Toolkit_very_important/ 
		test_dir=$clean_dir/data/${x}
		test_wav_file=$test_dir/wav.scp
 		test_text_file=$test_dir/text
		test_noise_dir=$noise_dir/data/${x}_kn_noise
		[ -d $test_noise_dir ] && rm -rf $test_noise_dir
		mkdir -p $test_noise_dir 

		echo "generate $test_noise_dir/wav.scp"
		while read p; do
    		n=`shuf -n 1 $noises`
    		noise=`echo $n | cut -d' ' -f2`
			noisetype=`echo $n | cut -d' ' -f1`
    		#snr=$(($RANDOM % 5))
   
    		uid=`echo $p | cut -d' ' -f1`
    		wav=`echo $p | cut -d' ' -f2-`
   
    		#echo "Add noise utterance ..."
    		echo "${uid}-${noisetype} python $d_cmd -r 16000 -c noise[filter=$noise,snr=$snr] $wav stdout.wav |" >> $test_noise_dir/wav.scp
			trans=`grep "${uid}" $test_dir/text | cut -d' ' -f2-`
			echo "${uid}-${noisetype} $trans" >> $test_noise_dir/text
			echo "${uid}-${noisetype} ${uid}-${noisetype}" >> $test_noise_dir/utt2spk
		done < $test_wav_file

		cat $test_noise_dir/text | sort -u > $test_noise_dir/text.tmp
		mv $test_noise_dir/text.tmp $test_noise_dir/text

		echo "generate $test_noise_dir/spk2utt"
		cd $noise_dir 
		sort -k 2 $test_noise_dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $test_noise_dir/spk2utt 
		utils/fix_data_dir.sh $test_noise_dir
		utils/validate_data_dir.sh --no-feats $test_noise_dir || exit 1;
	done
fi

echo "Finish!"

