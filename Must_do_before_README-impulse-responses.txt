### Install scikits.audiolab ###
1. Download libsndfile-1.0.28 and decommpress it
	./configure --prefix=/home/users0/licu/
	make
	make install

2. Download scikits.audiolab-0.11.0 and decompress it 
3. Add libsndfile path to site.cfg of scikits.audiolab
	cd scikits.audiolab-0.11.0/
	vim site.cfg

[sndfile]
include_dirs = /home/users0/licu/include
library_dirs = /home/users0/licu/lib 
sndfile_libs = sndfile-1

	python setup.py install


### Install scikits.samplerate ###
1. Download libsamplerate-0.1.9 and decompress it
        ./configure --prefix=/home/users0/licu/
        make
        make install

2. Download scikits.samplerate-0.3.3 and decompress it
3. Add lib libsamplerate path to site.cfg of scikits.samplerate
	cd scikits.samplerate-0.3.3/
	vim site.cfg

[samplerate]
include_dirs = /home/users0/licu/include
library_dirs = /home/users0/licu/lib 

	python setup.py install
