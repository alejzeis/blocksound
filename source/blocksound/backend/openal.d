/*
 *  zlib License
 *  
 *  (C) 2016 jython234
 *  
 *  This software is provided 'as-is', without any express or implied
 *  warranty.  In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *  
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, subject to the following restrictions:
 *  
 *  1. The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  2. Altered source versions must be plainly marked as such, and must not be
 *     misrepresented as being the original software.
 *  3. This notice may not be removed or altered from any source distribution.
*/
module blocksound.backend.openal;

version(blocksound_ALBackend) {

    pragma(msg, "-----BlockSound using OpenAL backend-----");

    import blocksound.core;
    import blocksound.backend.types;

    import derelict.openal.al;
    import derelict.sndfile.sndfile;

    /// Class to manage the OpenAL Audio backend.
    class ALAudioBackend : AudioBackend {
        protected ALCdevice* device;
        protected ALCcontext* context;

        /// Create a new ALBackend. One per thread.
        this() @trusted {
            debug(blocksound_verbose) {
                import std.stdio : writeln;
                writeln("[BlockSound]: Initializing OpenAL backend...");
            }

            device = alcOpenDevice(null); // Open default device.
            context = alcCreateContext(device, null);

            alcMakeContextCurrent(context);

            debug(blocksound_verbose) {
                import std.stdio : writeln;
                writeln("[BlockSound]: OpenAL Backend initialized.");
                writeln("[BlockSound]: AL_VERSION: ", toDString(alGetString(AL_VERSION)), ", AL_VENDOR: ", toDString(alGetString(AL_VENDOR)));
            }
        }

        override {
            void setListenerLocation(in Vec3 loc) @trusted nothrow {
                alListener3f(AL_POSITION, loc.x, loc.y, loc.z);
            }

            void setListenerGain(in float gain) @trusted nothrow {
                alListenerf(AL_GAIN, gain);
            }

            void cleanup() @trusted nothrow {
                alcCloseDevice(device);
            }
        }
    }

    /// OpenAL Source backend
    class ALSource : Source {
        private ALuint source;

        package this() {
            alGenSources(1, &source);
        }

        override {
            protected void _setSound(Sound sound) @trusted {
                if(auto s = cast(ALSound) sound) {
                    alSourcei(source, AL_BUFFER, s.buffer);
                } else {
                    throw new Exception("Invalid Sound: not instance of ALSound");
                }
            }

            void setLooping(in bool loop) @trusted {
                alSourcei(source, AL_LOOPING, loop ? AL_TRUE : AL_FALSE);
            }
 
            void play() @trusted nothrow {
                alSourcePlay(source);
            }

            void pause() @trusted nothrow {
                alSourcePause(source);
            }

            void stop() @trusted nothrow {
                alSourceStop(source);
            }

            bool hasFinishedPlaying() @trusted nothrow {
                ALenum state;
                alGetSourcei(source, AL_SOURCE_STATE, &state);
                return state != AL_PLAYING;
            }

            protected void _cleanup() @system nothrow {
                alDeleteSources(1, &source);
            }
        }
    }

    class ALStreamingSource : StreamingSource {
        import std.concurrency;

        static immutable size_t
            STREAM_CMD_PLAY = 0,
            STREAM_CMD_PAUSE = 1,
            STREAM_CMD_STOP = 2,
            STREAM_IS_PLAYING = 3,
            STREAM_STATE_PLAYING = 4,
            STREAM_STATE_STOPPED = 5;

        package ALuint source;

        private Tid streamThread;
        private ALStreamedSound sound;

        package this() {
            alGenSources(1, &source);
        }

        override {
            protected void _setSound(Sound sound) @trusted {
                if(!(this.sound is null)) throw new Exception("Sound already set!");

                if(auto s = cast(ALStreamedSound) sound) {
                    this.sound = s;

                    alSourceQueueBuffers(source, s.numBuffers, s.buffers.ptr);
                    streamThread = spawn(&streamSoundThread, cast(shared) this, cast(shared) this.sound);
                } else {
                    throw new Exception("Invalid Sound: not instance of ALStreamedSound");
                }
            }

            void setLooping(in bool loop) @trusted {
                //alSourcei(source, AL_LOOPING, loop ? AL_TRUE : AL_FALSE);
                //TODO
            }
 
            void play() @trusted {
                alSourcePlay(source);
                streamThread.send(STREAM_CMD_PLAY);
            }

            void pause() @trusted {
                alSourcePause(source);
                send(streamThread, STREAM_CMD_PAUSE);
            }

            void stop() @trusted {
                alSourceStop(source);
                send(streamThread, STREAM_CMD_STOP);
            }

            bool hasFinishedPlaying() @trusted nothrow {
                //TODO: THREAD!
                ALenum state;
                alGetSourcei(source, AL_SOURCE_STATE, &state);
                return state != AL_PLAYING;
            }

            protected void _cleanup() @system nothrow {
                alDeleteSources(1, &source);
            }
        }
    }   

    package void streamSoundThread(shared ALStreamingSource source, shared ALStreamedSound sound) @system {
        import std.concurrency;
        import std.datetime;
        import core.thread;

        bool hasFinished = false;
        bool isPlaying = false;
        
        while(true) {
            receiveTimeout(dur!("msecs")(1), 
                (immutable size_t signal) {
                    switch(signal) {
                        case ALStreamingSource.STREAM_CMD_PLAY:
                            isPlaying = true;
                            break;
                        default:
                            break;
                    }
            });

            if(isPlaying) {
                // TODO: Streaming here
                ALint state, processed;

                alGetSourcei(source.source, AL_SOURCE_STATE, &state);
                alGetSourcei(source.source, AL_BUFFERS_PROCESSED, &processed);
                if(processed > 0) {
                    alSourceUnqueueBuffers(cast(ALuint) source.source, processed, (cast(ALuint[])sound.buffers).ptr);

                    alDeleteBuffers(processed, (cast(ALuint[])sound.buffers).ptr);
                    for(size_t i = 0; i < processed; i++) {
                        try {
                            ALuint buffer = (cast(ALStreamedSound) sound).queueBuffer();
                            sound.buffers[i] = buffer;
                            /*debug {
                                import std.stdio;
                                writeln("refill ", i, " ", processed);
                            }*/
                        } catch(Exception e) {
                            throw new Exception("CAUGHT EOF!");
                        }
                    }

                    alSourceQueueBuffers(cast(ALuint) source.source, processed, (cast(ALuint[])sound.buffers).ptr);
                }
                if(state != AL_PLAYING) {
                    alSourcePlay(source.source);
                }

                Thread.sleep(dur!("msecs")(25));
            }

            if(hasFinished) {
                break;
            }
        }
    }

    /// OpenAL Sound backend
    class ALSound : Sound {
        private ALuint _buffer;

        @property ALuint buffer() @safe nothrow { return _buffer; }

        protected this(ALuint buffer) @safe nothrow {
            _buffer = buffer;
        }

        static ALSound loadSound(in string filename) @trusted {
            return new ALSound(loadSoundToBuffer(filename));
        }

        override void cleanup() @trusted nothrow {
            alDeleteBuffers(1, &_buffer);
        }
    }

    /// OpenAL Sound backend (for streaming)
    class ALStreamedSound : StreamedSound {
        private SF_INFO soundInfo;
        private SNDFILE* file;

        package ALuint numBuffers;
        package ALuint[] buffers;

        private this(SF_INFO soundInfo, SNDFILE* file, ALuint numBuffers) @safe {
            this.soundInfo = soundInfo;
            this.file = file;
            this.numBuffers = numBuffers;

            buffers = new ALuint[numBuffers];
        }

        static ALStreamedSound loadSound(in string filename, in ALuint bufferNumber = 2) @system {
            import std.exception : enforce;
            import std.file : exists;

            enforce(INIT, new Exception("BlockSound has not been initialized!"));
            enforce(exists(filename), new Exception("File \"" ~ filename ~ "\" does not exist!"));

            SF_INFO info;
            SNDFILE* file;

            file = sf_open(toCString(filename), SFM_READ, &info);

            // Fix for OGG pops and crackles.
            sf_command(file, SFC_SET_SCALE_FLOAT_INT_READ, cast(void*) 1, cast(int) byte.sizeof);

            ALStreamedSound sound =  new ALStreamedSound(info, file, bufferNumber);
            for(size_t i = 0; i < bufferNumber; i++) {
                ALuint buffer = sound.queueBuffer();
                sound.buffers[i] = buffer;
            }

            return sound;
        }

        private ALuint queueBuffer() @system {
            ALuint buffer;
            alGenBuffers(1, &buffer);

            AudioBuffer ab = sndfile_readShorts(file, soundInfo, 4800);
            alBufferData(buffer, soundInfo.channels == 1 ? AL_FORMAT_MONO16 : AL_FORMAT_STEREO16, ab.data.ptr, cast(int) (ab.data.length * short.sizeof), soundInfo.samplerate);
            return buffer;
        }

        override {
            void cleanup() @trusted {
                alDeleteBuffers(numBuffers, buffers.ptr);
                sf_close(file);
            }
        }
    }

    AudioBuffer sndfile_readShorts(SNDFILE* file, SF_INFO info, size_t frames) @system {
        AudioBuffer ab;

        ab.data = new short[frames * info.channels];

        if((ab.remaining = sf_read_short(file, ab.data.ptr, ab.data.length)) == 0) {
            throw new Exception("EOF!");
        } 

        return ab;
    }

    
    package struct AudioBuffer {
        short[] data;
        sf_count_t remaining;
    }

    /++
        Loads a sound from a file into an OpenAL buffer.
        Uses libsndfile for file reading.

        Params:
                filename =  The filename where the sound is located.
        
        Throws: Exception if file is not found, or engine is not initialized.
        Returns: An OpenAL buffer containing the sound.
    +/
    ALuint loadSoundToBuffer(in string filename) @system {
        import std.exception : enforce;
        import std.file : exists;

        enforce(INIT, new Exception("BlockSound has not been initialized!"));
        enforce(exists(filename), new Exception("File \"" ~ filename ~ "\" does not exist!"));

        SF_INFO info;
        SNDFILE* file = sf_open(toCString(filename), SFM_READ, &info);

        // Fix for OGG pops and crackles.
        sf_command(file, SFC_SET_SCALE_FLOAT_INT_READ, cast(void*) 1, cast(int) byte.sizeof);

        short[] data;
        short[] readBuf = new short[4096];

        long readSize = 0;
        while((readSize = sf_read_short(file, readBuf.ptr, readBuf.length)) != 0) {
            data ~= readBuf[0..(cast(size_t) readSize)];
        }

        ALuint buffer;
        alGenBuffers(1, &buffer);
        alBufferData(buffer, info.channels == 1 ? AL_FORMAT_MONO16 : AL_FORMAT_STEREO16, data.ptr, cast(int) (data.length * short.sizeof), info.samplerate);

        sf_close(file);

        return buffer;
    }

    /++
        Loads libraries required by the OpenAL backend.
        This is called automatically by blocksound's init
        function.

        Params:
                skipALload =    Skips loading OpenAL from derelict.
                                Set this to true if your application loads
                                OpenAL itself before blocksound does.

                skipSFLoad =    Skips loading libsndfile from derelict.
                                Set this to true if your application loads
                                libsdnfile itself before blocksound does.
    +/
    void loadLibraries(bool skipALload = false, bool skipSFload = false) @system {
        if(!skipALload) {
            version(Windows) {
                try {
                    DerelictAL.load(); // Search for system libraries first.
                    debug(blocksound_verbose) notifyLoadLib("OpenAL");
                } catch(Exception e) {
                    DerelictAL.load("lib\\openal32.dll"); // Try to use provided library.
                    debug(blocksound_verbose) notifyLoadLib("OpenAL");
                }
            } else {
                DerelictAL.load();
                debug(blocksound_verbose) notifyLoadLib("OpenAL");
            }
        }

        if(!skipSFload) {
            version(Windows) {
                try {
                    DerelictSndFile.load(); // Search for system libraries first.
                    debug(blocksound_verbose) notifyLoadLib("libsndfile");
                } catch(Exception e) {
                    DerelictSndFile.load("lib\\libsndfile-1.dll"); // Try to use provided library.
                    debug(blocksound_verbose) notifyLoadLib("libsndfile");
                }
            } else {
                DerelictSndFile.load();
                debug(blocksound_verbose) notifyLoadLib("libsndfile");
            }
        }
    }
}