# Phone
This module takes care of initializing the phone and answering calls.
After answering, it will play a song.

It is set up to have 2 .wav files - one to play normally, and one to
play after too many calls from the same number.  
The files should be included in the 'priv' direcotry

normalWav - the file you want to play normally.   Default is set from build-time env variable   NORMAL_WAV
limitWav  - the file to play after the rate limit  Default is set from build-time env variable   LIMITED_WAV
limit     - the number of calls per period before being limited (default is 2)
time      - seconds between limit reset (default 8 hours: 8*3600)
