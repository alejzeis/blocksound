module blocksound.backend.openal;

version(blocksound_ALBackend) {

    pragma(msg, "-----Using OpenAL backend-----");

    import blocksound.core;
    import blocksound.backend.backend;

    import derelict.openal.al;
    import derelict.sndfile.sndfile;

    /// Class to manage the OpenAL backend.
    class ALBackend : Backend {
        protected ALCdevice* device;
        protected ALCcontext* context;

        /// Create a new ALBackend. One per thread.
        this() @trusted nothrow {
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
    ALuint loadSoundToBuffer(in string filename) @trusted {
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
}