#!/bin/bash
 
d_cmd=/mount/arbeitsdaten/asr/licu/Toolkit_very_important/acoustic-simulator/degrade-audio.py # degrade audio command
## Remember to change SNR
tag=snr08
noises=/mount/arbeitsdaten/asr/licu/Toolkit_very_important/kn_noises_wsj_${tag}.txt # testing noises file
#noises=/mount/arbeitsdaten/asr/licu/Toolkit_very_important/acoustic-simulator/noise-file-list-test.txt # testing noises file
#spaces=`pwd`/acoustic-simulator/train-spaces

dir=/mount/arbeitsdaten/asr/licu/kaldi-trunk3/egs/wsj/s5 
test_dir_1=${dir}/data/test_dev93 # clean directory
test_dir_2=${dir}/data/test_eval92 # clean directory

noise_dir=/mount/arbeitsdaten/asr/licu/kaldi-trunk3/egs/wsj/s5_$tag
test_noise_dir_1=${noise_dir}/data/test_dev93_kn_noise # noise directory
test_noise_dir_2=${noise_dir}/data/test_eval92_kn_noise # noise directory

[ -d $test_noise_dir_1 ] && rm -rf $test_noise_dir_1
[ -d $test_noise_dir_2 ] && rm -rf $test_noise_dir_2
mkdir -p $test_noise_dir_1
mkdir -p $test_noise_dir_2
 
echo "Start: generate noise wav.scp, text, utt2spk and spk2utt... for $test_noise_dir"
for set in 1 2; do
	p=test_dir_$set
	np=test_noise_dir_$set
	wav_file=${!p}/wav.scp
	text_file=${!p}/text
	outdir=${!np}
	echo "wav_file: $wav_file"
	echo "outdir: $outdir"
	count=1
	while read p; do
    	noise=`shuf -n 1 $noises`
		#noise=`sed -n "${count}p" $noises`
		#echo $count $noise
		#count=$((($count+1)%435))
    	snr=$(( $RANDOM % 9 )) # random snr between 0 and 20
   
    	uid=`echo $p | cut -d' ' -f1`
    	wav=`echo $p | cut -d' ' -f2-`

    	echo "${uid}-noise $wav python $d_cmd -r 16000 -c noise[filter=$noise,snr=$snr] stdin.wav stdout.wav |" >> $outdir/wav.scp
		trans=`grep "${uid}" $text_file | cut -d' ' -f2-`                
        echo "${uid}-noise $trans" >> $outdir/text
	done < $wav_file
	cat $outdir/wav.scp | sort -u > $outdir/wav.scp.u; mv $outdir/wav.scp.u $outdir/wav.scp
	cat $outdir/text | sort -u > $outdir/text.u; mv $outdir/text.u $outdir/text

	echo "generate $outdir/utt2spk"         
	less -c $outdir/wav.scp | awk '{spk=substr($1,1,4);printf("%s %s\n", $1, spk)}' | sort -u > $outdir/utt2spk

	echo "generate $outdir/spk2utt"        
	cd $noise_dir        
	sort -k 2 $outdir/utt2spk | utils/utt2spk_to_spk2utt.pl > $outdir/spk2utt         
	utils/validate_data_dir.sh --no-feats $outdir
	cd /mount/arbeitsdaten/asr/licu/Toolkit_very_important/
done

echo "Finish! located at $test_noise_dir"
