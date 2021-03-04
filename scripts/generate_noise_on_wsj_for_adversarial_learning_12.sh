#!/bin/bash
set -e
stage=0 
acoustic_tool=/mount/arbeitsdaten/asr/licu/Toolkit_very_important/acoustic-simulator
d_cmd=$acoustic_tool/degrade-audio.py # degrade audio command
noises=$acoustic_tool/noise-file-all-label-train.txt # training noises file
test_noises=$acoustic_tool/noise-file-all-label-test.txt # test noises file
 
## clean directory
clean_dir=/mount/arbeitsdaten/asr/licu/kaldi-trunk3/egs/wsj/s5
train_dir=$clean_dir/data/train_si284
dev_dir=$clean_dir/data/test_dev93
eval_dir=$clean_dir/data/test_eval92
wav_file=$train_dir/wav.scp
text_file=$train_dir/text
dev_wav_file=$dev_dir/wav.scp
dev_text_file=$dev_dir/text
eval_wav_file=$eval_dir/wav.scp
eval_text_file=$eval_dir/text

## noise directory
tag=ad_snr012_1500C
noise_dir=/mount/arbeitsdaten/asr/licu/kaldi-trunk3/egs/wsj/s5_$tag
train_noise_dir=$noise_dir/data/train_si284 # noise directory
dev_noise_dir=$noise_dir/data/test_dev93_ukn # unknown noise directory
eval_noise_dir=$noise_dir/data/test_eval92_ukn # unknown noise directory
dev_kn_noise_dir=$noise_dir/data/test_dev93_kn # known noise directory
eval_kn_noise_dir=$noise_dir/data/test_eval92_kn # known noise directory

[ -d $train_noise_dir ] && rm -rf $train_noise_dir
mkdir -p $train_noise_dir 

[ -d $dev_noise_dir ] && rm -rf $dev_noise_dir
mkdir -p $dev_noise_dir 
[ -d $eval_noise_dir ] && rm -rf $eval_noise_dir
mkdir -p $eval_noise_dir 

[ -d $dev_kn_noise_dir ] && rm -rf $dev_kn_noise_dir
mkdir -p $dev_kn_noise_dir 
[ -d $eval_kn_noise_dir ] && rm -rf $eval_kn_noise_dir
mkdir -p $eval_kn_noise_dir 

ln -s $clean_dir/steps $noise_dir
ln -s $clean_dir/utils $noise_dir
ln -s $clean_dir/local $noise_dir
cp -a $clean_dir/conf $noise_dir
cp -a $clean_dir/data/lang $noise_dir/data
cp -a $clean_dir/data/local $noise_dir/data
cp $clean_dir/{path.sh,cmd.sh} $noise_dir

if [ $stage -le 0 ]; then
	echo "generate $train_noise_dir/wav.scp"
	while read p; do
    	n=`shuf -n 1 $noises`
    	noise=`echo $n | cut -d' ' -f2`
		noisetype=`echo $n | cut -d' ' -f1`
    	snr=$(($RANDOM % 13))
		#snr=1
   
    	uid=`echo $p | cut -d' ' -f1`
    	wav=`echo $p | cut -d' ' -f2-`

    	echo "${uid}-${noisetype} $wav python $d_cmd -r 16000 -c noise[filter=$noise,snr=$snr] stdin.wav stdout.wav |" >> $train_noise_dir/wav.scp
		trans=`grep "${uid}" $train_dir/text | cut -d' ' -f2-`
		echo "${uid}-${noisetype} $trans" >> $train_noise_dir/text
		dur=`grep "${uid}" $train_dir/utt2dur | cut -d' ' -f2`
		echo "${uid}-${noisetype} $dur" >> $train_noise_dir/utt2dur
	done < $wav_file
	cat $train_noise_dir/text | sort -u > $train_noise_dir/text.tmp
	mv $train_noise_dir/text.tmp $train_noise_dir/text
 
	echo "generate $train_noise_dir/utt2spk" 
	less -c $train_noise_dir/wav.scp | awk '{spk=substr($1,1,3);printf("%s %s\n", $1, spk)}' | sort -u > $train_noise_dir/utt2spk

	echo "generate $train_noise_dir/spk2utt"
	cd $noise_dir
	sort -k 2 $train_noise_dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $train_noise_dir/spk2utt 

	echo "copy $train_dir/spk2gender $train_noise_dir"
	cp $train_dir/spk2gender $train_noise_dir

	utils/validate_data_dir.sh --no-feats $train_noise_dir || exit 1;
fi

if [ $stage -le 1 ]; then
	cd /mount/arbeitsdaten/asr/licu/Toolkit_very_important/ 

	echo "generate $dev_noise_dir/wav.scp"
	while read p; do
    	n=`shuf -n 1 $test_noises`
    	noise=`echo $n | cut -d' ' -f2`
		noisetype=`echo $n | cut -d' ' -f1`
    	snr=$(($RANDOM % 13))
		#snr=1
   
    	uid=`echo $p | cut -d' ' -f1`
    	wav=`echo $p | cut -d' ' -f2-`
   
    	#echo "Add noise utterance ..."
    	echo "${uid}-${noisetype} $wav python $d_cmd -r 16000 -c noise[filter=$noise,snr=$snr] stdin.wav stdout.wav |" >> $dev_noise_dir/wav.scp
		trans=`grep "${uid}" $dev_dir/text | cut -d' ' -f2-`
		echo "${uid}-${noisetype} $trans" >> $dev_noise_dir/text
	done < $dev_wav_file
	cat $dev_noise_dir/text | sort -u > $dev_noise_dir/text.tmp
	mv $dev_noise_dir/text.tmp $dev_noise_dir/text

	echo "generate $dev_noise_dir/utt2spk" 
	less -c $dev_noise_dir/wav.scp | awk '{spk=substr($1,1,3);printf("%s %s\n", $1, spk)}' | sort -u > $dev_noise_dir/utt2spk

	echo "generate $dev_noise_dir/spk2utt"
	cd $noise_dir 
	sort -k 2 $dev_noise_dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $dev_noise_dir/spk2utt 

	echo "copy $dev_dir/spk2gender to $dev_noise_dir"
	cp $dev_dir/spk2gender $dev_noise_dir

	utils/validate_data_dir.sh --no-feats $dev_noise_dir || exit 1;
fi

if [ $stage -le 2 ]; then
	cd /mount/arbeitsdaten/asr/licu/Toolkit_very_important/ 

	echo "generate $dev_kn_noise_dir/wav.scp"
	while read p; do
    	n=`shuf -n 1 $noises`
    	noise=`echo $n | cut -d' ' -f2`
		noisetype=`echo $n | cut -d' ' -f1`
    	snr=$(($RANDOM % 13))
		#snr=1
   
    	uid=`echo $p | cut -d' ' -f1`
    	wav=`echo $p | cut -d' ' -f2-`
   
    	#echo "Add noise utterance ..."
    	echo "${uid}-${noisetype} $wav python $d_cmd -r 16000 -c noise[filter=$noise,snr=$snr] stdin.wav stdout.wav |" >> $dev_kn_noise_dir/wav.scp
		trans=`grep "${uid}" $dev_dir/text | cut -d' ' -f2-`
		echo "${uid}-${noisetype} $trans" >> $dev_kn_noise_dir/text
	done < $dev_wav_file
	cat $dev_kn_noise_dir/text | sort -u > $dev_kn_noise_dir/text.tmp
	mv $dev_kn_noise_dir/text.tmp $dev_kn_noise_dir/text

	echo "generate $dev_kn_noise_dir/utt2spk" 
	less -c $dev_kn_noise_dir/wav.scp | awk '{spk=substr($1,1,3);printf("%s %s\n", $1, spk)}' | sort -u > $dev_kn_noise_dir/utt2spk

	echo "generate $dev_kn_noise_dir/spk2utt"
	cd $noise_dir 
	sort -k 2 $dev_kn_noise_dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $dev_kn_noise_dir/spk2utt 

	echo "copy $dev_dir/spk2gender to $dev_kn_noise_dir"
	cp $dev_dir/spk2gender $dev_kn_noise_dir

	utils/validate_data_dir.sh --no-feats $dev_kn_noise_dir || exit 1;
fi

if [ $stage -le 3 ]; then
	cd /mount/arbeitsdaten/asr/licu/Toolkit_very_important/ 

	echo "generate $eval_noise_dir/wav.scp"
	while read p; do
    	n=`shuf -n 1 $test_noises`
    	noise=`echo $n | cut -d' ' -f2`
		noisetype=`echo $n | cut -d' ' -f1`
    	snr=$(($RANDOM % 13))
		#snr=1
   
    	uid=`echo $p | cut -d' ' -f1`
    	wav=`echo $p | cut -d' ' -f2-`
   
    	#echo "Add noise utterance ..."
    	echo "${uid}-${noisetype} $wav python $d_cmd -r 16000 -c noise[filter=$noise,snr=$snr] stdin.wav stdout.wav |" >> $eval_noise_dir/wav.scp
		trans=`grep "${uid}" $eval_dir/text | cut -d' ' -f2-`
		echo "${uid}-${noisetype} $trans" >> $eval_noise_dir/text
	done < $eval_wav_file
	cat $eval_noise_dir/text | sort -u > $eval_noise_dir/text.tmp
	mv $eval_noise_dir/text.tmp $eval_noise_dir/text

	echo "generate $eval_noise_dir/utt2spk" 
	less -c $eval_noise_dir/wav.scp | awk '{spk=substr($1,1,3);printf("%s %s\n", $1, spk)}' | sort -u > $eval_noise_dir/utt2spk

	echo "generate $eval_noise_dir/spk2utt"
	cd $noise_dir 
	sort -k 2 $eval_noise_dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $eval_noise_dir/spk2utt 

	echo "copy $eval_dir/spk2gender $eval_noise_dir"
	cp $eval_dir/spk2gender $eval_noise_dir

	utils/validate_data_dir.sh --no-feats $eval_noise_dir || exit 1;
fi

if [ $stage -le 4 ]; then
	cd /mount/arbeitsdaten/asr/licu/Toolkit_very_important/ 

	echo "generate $eval_kn_noise_dir/wav.scp"
	while read p; do
    	n=`shuf -n 1 $noises`
    	noise=`echo $n | cut -d' ' -f2`
		noisetype=`echo $n | cut -d' ' -f1`
    	snr=$(($RANDOM % 13))
		#snr=1
   
    	uid=`echo $p | cut -d' ' -f1`
    	wav=`echo $p | cut -d' ' -f2-`
   
    	#echo "Add noise utterance ..."
    	echo "${uid}-${noisetype} $wav python $d_cmd -r 16000 -c noise[filter=$noise,snr=$snr] stdin.wav stdout.wav |" >> $eval_kn_noise_dir/wav.scp
		trans=`grep "${uid}" $eval_dir/text | cut -d' ' -f2-`
		echo "${uid}-${noisetype} $trans" >> $eval_kn_noise_dir/text
	done < $eval_wav_file
	cat $eval_kn_noise_dir/text | sort -u > $eval_kn_noise_dir/text.tmp
	mv $eval_kn_noise_dir/text.tmp $eval_kn_noise_dir/text

	echo "generate $eval_kn_noise_dir/utt2spk" 
	less -c $eval_kn_noise_dir/wav.scp | awk '{spk=substr($1,1,3);printf("%s %s\n", $1, spk)}' | sort -u > $eval_kn_noise_dir/utt2spk

	echo "generate $eval_kn_noise_dir/spk2utt"
	cd $noise_dir 
	sort -k 2 $eval_kn_noise_dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $eval_kn_noise_dir/spk2utt 

	echo "copy $eval_dir/spk2gender $eval_kn_noise_dir"
	cp $eval_dir/spk2gender $eval_kn_noise_dir

	utils/validate_data_dir.sh --no-feats $eval_kn_noise_dir || exit 1;
fi

echo "Finish!"

