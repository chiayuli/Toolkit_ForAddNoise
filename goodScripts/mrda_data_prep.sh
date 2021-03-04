. ./path.sh
. ./cmd.sh

#orig_data=/mount/arbeitsdaten34/projekte/slu/Daniel/Corpora/icsi/audios
MRDA=/mount/arbeitsdaten34/projekte/slu/Daniel/data_for_ASR/MRDA
path=/mount/arbeitsdaten/asr/licu/kaldi-trunk3/egs/mrda/s5

mkdir -p $path/data/train
mkdir -p $path/data/valid
mkdir -p $path/data/test

for set in "test" "valid"; 
do
	grep -v "NewDialog" $MRDA/ordered_sentences.$set | cut -f2 > $path/data/$set/utt
    grep -v "NewDialog" $MRDA/ordered_sentences.$set | cut -f3 > $path/data/$set/spkid
	paste -d'_' $path/data/$set/spkid $path/data/$set/utt > $path/data/$set/uttid
	grep -v "NewDialog" $MRDA/ordered_sentences.$set | cut -f4- | sed "s/  '/'/g" | sed "s/[?,.-]//g" | sed "s/  / /g" > $path/data/$set/trans

	## prepare utt2spk, spk2utt ##
	paste -d' ' $path/data/$set/uttid $path/data/$set/spkid > $path/data/$set/utt2spk
	utils/utt2spk_to_spk2utt.pl $path/data/$set/utt2spk > $path/data/$set/spk2utt

	## prepare text ##
	paste -d' ' $path/data/$set/uttid $path/data/$set/trans > $path/data/$set/text
	
	## prepare wav.scp ##
	paste -d' ' $path/data/$set/uttid $path/data/$set/utt | awk -v set="$set" '{printf "%s ",$1;printf "/mount/arbeitsdaten34/projekte/slu/Daniel/data_for_ASR/MRDA/%s/%s.wav\n",set,$2}' > $path/data/$set/wav.scp

	rm $path/data/$set/{utt,spkid,uttid,trans}
	utils/fix_data_dir.sh $path/data/$set/

	## feature extraction ##
	mfccdir=mfcc
	steps/make_mfcc.sh --nj 10 data/$set exp/make_mfcc/$set $mfccdir
	steps/compute_cmvn_stats.sh data/$set exp/make_mfcc/$set $mfccdir
 	utils/fix_data_dir.sh data/$set
	utils/validate_data_dir.sh $path/data/$set/
done

