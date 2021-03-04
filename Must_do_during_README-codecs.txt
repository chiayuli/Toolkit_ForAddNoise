Step 6 FFMPEG, Compile FFMPEG

export CPPFLAGS='-I/home/users0/licu/include'
export LDFLAGS='-L/home/users0/licu/lib/'
./configure --prefix=/home/users0/licu --enable-gpl --enable-libmp3lame --enable-nonfree --enable-libaacplus --disable-yasm
