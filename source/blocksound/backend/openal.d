module blocksound.backend.openal;

version(blocksound_ALBackend) {

    pragma(msg, "-----Using OpenAL backend-----");

    import blocksound.core;
    import blocksound.backend.backend;

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

            void play() @trusted nothrow {
                alSourcePlay(source);
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