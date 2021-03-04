#!/bin/bash
set -e
 
d_cmd=`pwd`/acoustic-simulator/degrade-audio.py # degrade audio command
## filters (noise, frequency response, impulse response) 
noises6=`pwd`/acoustic-simulator/noise-file-list-6t.txt # six noise categories: Car, Crowd of people (babble), Restaurant, Street, Airport, Train station
noises3=`pwd`/acoustic-simulator/noise-file-list-3t.txt # three noise categories which will be mixed with room impulse response: Crowd of people (babble), Restaurant, Airport
spaces=`pwd`/acoustic-simulator/spaces-file-list.txt
devices=`pwd`/acoustic-simulator/devices-file-list.txt
sample=16000
downsample=$1
bp=('g712' 'p341' 'irs' 'mirs')
## clean directory
train_dir=/mount/arbeitsdaten/asr/licu/kaldi-trunk3/egs/librispeech/s5/data/train_clean_460
## noise directory
tag="d$1"
train_noise_dir=/mount/arbeitsdaten/asr/licu/kaldi-trunk3/egs/librispeech/s5_$tag/data/train_mix_460 # noise directory

[ ! -d $train_noise_dir ] && mkdir -p $train_noise_dir 
#ln -s $train_dir/../../steps $train_noise_dir/../../
#ln -s $train_dir/../../utils $train_noise_dir/../../
#ln -s $train_dir/../../local $train_noise_dir/../../
#cp -a $train_dir/../../conf $train_noise_dir/../../

echo "generate $train_noise_dir/wav.scp"
while read p; do
	uid=`echo $p | cut -d' ' -f1`
	wav=`echo $p | cut -d' ' -f2-`
	last="|"
	if [ "$downsample" == "y" ]; then
		last="| sox - -r 8000 -t wav - |"
	fi
   
	#0: clean (original speech)
	echo "${uid}0 $wav" >> $train_noise_dir/wav.scp

	#1: +noise 
	f=`shuf -n 1 $noises6` # pick one of six noise categories
	snr=$(( RANDOM % 10 + 5 )) # random snr between 5 and 15
	echo "${uid}1 $wav python $d_cmd -r $sample -c noise[filter=$f,snr=$snr] stdin.wav stdout.wav $last" >> $train_noise_dir/wav.scp

	#2: +room impulse response  
	f=`shuf -n 1 $spaces`
	w=$(( RANDOM % 51 + 25 )) # random wet between 25 and 75
	echo "${uid}2 $wav python $d_cmd -r $sample -c irspace[wet=$w,filter=$f] stdin.wav stdout.wav $last" >> $train_noise_dir/wav.scp

	#3: +device impulse response
	f=`shuf -n 1 $devices`
	echo "${uid}3 $wav python $d_cmd -r $sample -c irdevice[filter=$f] stdin.wav stdout.wav $last" >> $train_noise_dir/wav.scp

	#4: +noise +room impulse response
	f=`shuf -n 1 $noises3` # pick one of four noise categories which will be mixed with room impulse response
	snr=$(( RANDOM % 10 + 5 )) # random snr between 5 and 15
	f2=`shuf -n 1 $spaces`
	w=$(( RANDOM % 51 + 25 )) # random wet between 25 and 75
	echo "${uid}4 $wav python $d_cmd -r $sample -c noise[filter=$f,snr=$snr] stdin.wav stdout.wav | python $d_cmd -r $sample -c irspace[wet=$w,filter=$f2] stdin.wav stdout.wav $last" >> $train_noise_dir/wav.scp
	
	#5: +device impulse response +noise
	f=`shuf -n 1 $devices`
	f2=`shuf -n 1 $noises6` # pick one of six noise categories
	snr=$(( RANDOM % 10 + 5 )) # random snr between 5 and 15
	echo "${uid}5 $wav python $d_cmd -r $sample -c irdevice[filter=$f] stdin.wav stdout.wav | python $d_cmd -r $sample -c noise[filter=$f2,snr=$snr] stdin.wav stdout.wav $last" >> $train_noise_dir/wav.scp
    
	#6: +frequency response (Telephone band-pass filter: g712, p341, irs, mirs)
	i=$(( RANDOM % 4 )) # index for bp
	f=${bp[$i]}
	echo "${uid}6 $wav python $d_cmd -r $sample -c bp[ft=$f] stdin.wav stdout.wav $last" >> $train_noise_dir/wav.scp

	#7: +noise +frequency response (Telephone band-pass filter: g712, p341, irs, mirs)
	f=`shuf -n 1 $noises6` # pick one of six noise categories
	snr=$(( RANDOM % 10 + 5 )) # random snr between 5 and 15
	i=$(( RANDOM % 4 )) # index for bp
	f2=${bp[$i]}
	echo "${uid}7 $wav python $d_cmd -r $sample -c noise[filter=$f,snr=$snr] stdin.wav stdout.wav | python $d_cmd -r $sample -c bp[ft=$f2] stdin.wav stdout.wav $last" >> $train_noise_dir/wav.scp
	
	#8: +noise +room impulse response +frequency response (Telephone band-pass filter: g712, p341, irs, mirs)
	f=`shuf -n 1 $noises3` # pick one of four noise categories which will be mixed with room impulse response
	snr=$(( RANDOM % 10 + 5 )) # random snr between 5 and 15
	f2=`shuf -n 1 $spaces`
	w=$(( RANDOM % 51 + 25 )) # random wet between 25 and 75
	i=$(( RANDOM % 4 )) # index for bp
	f3=${bp[$i]}
	echo "${uid}8  $wav python $d_cmd -r $sample -c noise[filter=$f,snr=$snr] stdin.wav stdout.wav | python $d_cmd -r $sample -c irspace[wet=$w,filter=$f2] stdin.wav stdout.wav | python $d_cmd -r $sample -c bp[ft=$f3] stdin.wav stdout.wav $last" >> $train_noise_dir/wav.scp
	
	#9: +device impulse response +noise +frequency response (Telephone band-pass filter: g712, p341, irs, mirs)
	f=`shuf -n 1 $devices`
	f2=`shuf -n 1 $noises6` # pick one of six noise categories
	snr=$(( RANDOM % 10 + 5 )) # random snr between 5 and 15
	i=$(( RANDOM % 4 )) # index for bp
	f3=${bp[$i]}
	echo "${uid}9 $wav python $d_cmd -r $sample -c irdevice[filter=$f] stdin.wav stdout.wav | python $d_cmd -r $sample -c noise[filter=$f2,snr=$snr] stdin.wav stdout.wav | python $d_cmd -r $sample -c bp[ft=$f3] stdin.wav stdout.wav $last" >> $train_noise_dir/wav.scp

done < $train_dir/wav.scp

echo "generate $train_noise_dir/text"
cat $train_dir/text | awk '{for(j=0;j<10;j++){printf "%s%d ",$1,j;for(i=2;i<=NF;i++){printf "%s ",$i};printf "\n";}}' > $train_noise_dir/text

echo "generate $train_noise_dir/utt2spk" 
less -c $train_noise_dir/wav.scp | awk '{split($1,a,"-");printf("%s %s-%s\n",$1,a[1],a[2])}' > $train_noise_dir/utt2spk

echo "generate $train_noise_dir/spk2utt"
cd $train_noise_dir/../../ 
sort -k 2 $train_noise_dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $train_noise_dir/spk2utt 

utils/validate_data_dir.sh --no-feats $train_noise_dir

echo "Finish !!"
