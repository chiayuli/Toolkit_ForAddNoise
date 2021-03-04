#!/bin/bash
set -e
stage=0 
acoustic_tool=/mount/arbeitsdaten/asr/licu/Toolkit_very_important/acoustic-simulator
d_cmd=$acoustic_tool/degrade-audio.py # degrade audio command
noises=$acoustic_tool/noise-file-all-label-train.txt # training noises file
tst_noises=$acoustic_tool//noise-file-all-label-test.txt # test noises file
#spaces=`pwd`/train-spaces
 
## clean directory
clean_dir=$1
train_set=train
test_set="valid test"
test_unk_set="valid_unk test_unk"

## noise directory
tag=noi
noise_dir=${clean_dir}_$tag
mkdir -p $noise_dir/data
cp -a $clean_dir/data/${train_set} $noise_dir/data/${train_set}
rm $noise_dir/data/${train_set}/{feats.scp,cmvn.scp,cmvn.ark,utt2dur,utt2num_frames}

for set in $test_set ; 
do
	cp -a $clean_dir/data/$set $noise_dir/data/$set
	cp -a $clean_dir/data/$set $noise_dir/data/${set}_unk
	rm $noise_dir/data/$set/{feats.scp,cmvn.scp,utt2dur,utt2num_frames}
	rm $noise_dir/data/${set}_unk/{feats.scp,cmvn.scp,utt2dur,utt2num_frames}
done

if [ $stage -le 0 ]; then
	ln -s $clean_dir/steps $noise_dir
	ln -s $clean_dir/utils $noise_dir
	ln -s $clean_dir/local $noise_dir
	cp -a $clean_dir/conf $noise_dir
	cp $clean_dir/{path.sh,cmd.sh} $noise_dir
fi

if [ $stage -le 1 ]; then
	echo "generate noise wav.scp"
	for set in "train" "valid" "test" ;
	do
		[ -f $noise_dir/data/$set/wav.scp ] && rm $noise_dir/data/$set/wav.scp 
		while read p; do
    		n=`shuf -n 1 $noises`
    		noise=`echo $n | cut -d' ' -f2-`
    		snr=$(($RANDOM % 21))

    		echo "$p python $d_cmd -r 16000 -c noise[filter=$noise,snr=$snr] stdin.wav stdout.wav |" >> $noise_dir/data/$set/wav.scp
		done < $clean_dir/data/$set/wav.scp
		cd $noise_dir
		utils/fix_data_dir.sh $noise_dir/data/$set || exit 1;
		utils/validate_data_dir.sh --no-feats $noise_dir/data/$set || exit 1;
	done
fi
exit
if [ $stage -le 1 ]; then
	cd /mount/arbeitsdaten/asr/licu/Toolkit_very_important/
	echo "generate unknown noise wav.scp"
	for set in $test_unk_set ;
	do
		[ -f $noise_dir/$set/wav.scp ] && rm $noise_dir/$set/wav.scp 
		while read p; do
    		n=`shuf -n 1 $tst_noises`
    		noise=`echo $n | cut -d' ' -f2-`
    		snr=$(($RANDOM % 21))

    		echo "UNK$p |  python $d_cmd -r 16000 -c noise[filter=$noise,snr=$snr] stdin.wav stdout.wav |" >> $noise_dir/$set/wav.scp
		done < $clean_dir/data/$set/wav.scp
		less -c $noise_dir/$set/utt2spk | awk '{printf("UNK%s UNK%s\n",$1,$2)}'
		less -c $noise_dir/$set/text | awk '{printf("UNK%s UNK%s\n",$1,$2)}'
		cd $noise_dir/$set
		utils/fix_data_dir.sh $train_noise_dir || exit 1;
		utils/validate_data_dir.sh --no-feats $train_noise_dir || exit 1;
	done
fi

if [ $stage -le 1 ]; then
	cd /mount/arbeitsdaten/asr/licu/Toolkit_very_important/ 

	echo "generate $test_noise_dir/wav.scp"
	while read p; do
    	n=`shuf -n 1 $tst_noises`
    	noise=`echo $n | cut -d' ' -f2`
		noisetype=`echo $n | cut -d' ' -f1`
    	snr=$(($RANDOM % 21))
   
    	uid=`echo $p | cut -d' ' -f1`
    	wav=`echo $p | cut -d' ' -f2-`
   
    	#echo "Add noise utterance ..."
    	echo "${uid} $wav python $d_cmd -r 16000 -c noise[filter=$noise,snr=$snr] stdin.wav stdout.wav |" >> $test_noise_dir/wav.scp
		#trans=`grep "${uid}" $test_dir/text | cut -d' ' -f2-`
		#echo "${uid}-${noisetype} $trans" >> $test_noise_dir/text
	done < $test_wav_file
	cp ${test_dir}/{text,utt2spk,spk2utt,segments} $test_noise_dir/
	#cat $test_noise_dir/text | sort -u > $test_noise_dir/text.tmp
	#mv $test_noise_dir/text.tmp $test_noise_dir/text

	#echo "generate $test_noise_dir/utt2spk" 
	#less -c $test_noise_dir/wav.scp | awk '{spk=substr($1,1,9);printf("%s %s\n", $1, spk)}' | sort -u > $test_noise_dir/utt2spk

	#echo "generate $test_noise_dir/spk2utt"
	cd $noise_dir 
	#sort -k 2 $test_noise_dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $test_noise_dir/spk2utt 

	utils/fix_data_dir.sh $test_noise_dir || exit 1;
	utils/validate_data_dir.sh --no-feats $test_noise_dir || exit 1;
fi

if [ $stage -le 2 ]; then
	cd /mount/arbeitsdaten/asr/licu/Toolkit_very_important/ 

	echo "generate $test_noise_dir2/wav.scp"
	while read p; do
    	n=`shuf -n 1 $noises`
    	noise=`echo $n | cut -d' ' -f2`
		noisetype=`echo $n | cut -d' ' -f1`
    	snr=$(($RANDOM % 5))
   
    	uid=`echo $p | cut -d' ' -f1`
    	wav=`echo $p | cut -d' ' -f2-`
   
    	#echo "Add noise utterance ..."
    	echo "${uid}-${noisetype} $wav python $d_cmd -r 16000 -c noise[filter=$noise,snr=$snr] stdin.wav stdout.wav |" >> $test_noise_dir2/wav.scp
		trans=`grep "${uid}" $test_dir/text | cut -d' ' -f2-`
		echo "${uid}-${noisetype} $trans" >> $test_noise_dir2/text
	done < $test_wav_file
	cat $test_noise_dir2/text | sort -u > $test_noise_dir2/text.tmp
	mv $test_noise_dir2/text.tmp $test_noise_dir2/text

	echo "generate $test_noise_dir2/utt2spk" 
	less -c $test_noise_dir2/wav.scp | awk '{spk=substr($1,1,9);printf("%s %s\n", $1, spk)}' | sort -u > $test_noise_dir2/utt2spk

	echo "generate $test_noise_dir2/spk2utt"
	cd $noise_dir 
	sort -k 2 $test_noise_dir2/utt2spk | utils/utt2spk_to_spk2utt.pl > $test_noise_dir2/spk2utt 

	utils/fix_data_dir.sh $test_noise_dir2 || exit 1;
	utils/validate_data_dir.sh --no-feats $test_noise_dir2 || exit 1;
fi


echo "Finish!"

