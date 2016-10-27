module blocksound.backend.openal;

import blocksound.audio;
import blocksound.util;
import blocksound.core;
import blocksound.backend.core;

import derelict.openal.al;
import derelict.sndfile.sndfile;

import std.conv;

private template LoadLibrary(string libName, string suffix, string winName) {
    const char[] LoadLibrary = "
    version(Windows) {
        try {
            Derelict" ~ suffix ~ ".load();
            blocksound_getBackend().logger.logDebug(\"Loaded " ~ libName ~ "\");
        } catch(Exception e) {
            blocksound_getBackend().logger.logDebug(\"Failed to load library \" ~ libName ~ \", searching in provided libs\");
            try {
                Derelict" ~ suffix ~ ".load(\"lib/" ~ winName ~ ".dll\");
                blocksound_getBackend().logger.logDebug(\"Loaded " ~ libName ~ "\");
            } catch(Exception e) {
                throw new Exception(\"Failed to load library " ~ libName ~ ": e.toString()\");
            }
        }
    } else {
        try {
            Derelict" ~ suffix ~ ".load();
            blocksound_getBackend().logger.logDebug(\"Loaded " ~ libName ~ "\");
        } catch(Exception e) {
            throw new Exception(\"Failed to load library " ~ libName ~ ": e.toString()\");
        }
    }";
}

class ALBackend : Backend {

    this(BlockSoundLogger logger) @safe nothrow {
        super(logger);
    }

    override {
        void doInit() @system {
            mixin(LoadLibrary!("OpenAL", "AL", "openal32"));
            mixin(LoadLibrary!("libsndfile", "SndFile", "libsndfile-1"));
        }
        
        void doDestroy() @system {
            
        }
    }
}

class ALAudioManager : AudioManager {
    private ALCdevice* device;
    private ALCcontext* context;

    this(Vec3 listenerLocation, float gain) @safe {
        super(listenerLocation, gain);

        setupAL();
    }

    private void setupAL() @trusted {
        device = alcOpenDevice(null);
        context = alcCreateContext(device, null);

        alcMakeContextCurrent(context);
    }

    override {
        protected void setListenerLocation(Vec3 listenerLocation) @system {
            alListener3f(AL_POSITION, listenerLocation.x, listenerLocation.y, listenerLocation.z);
        }

        protected void setGain(float gain) @system {
            alListenerf(AL_GAIN, gain);
        }

        protected void doCleanup() @system {
            alcCloseDevice(device);
        }
    }
}

class ALSource : Source {
    private ALuint source;

    this(AudioManager manager, Vec3 location) @safe {
        super(manager, location);

        setupSource();
    }

    private void setupSource() @trusted nothrow {
        alGenSources(1, &source);
    }

    override {
        protected void setLocation(Vec3 location) @system {
            alSource3f(source, AL_POSITION, location.x, location.y, location.z);
        }

        protected void setSound(Sound sound) @system {
            ALSound sound_ = cast(ALSound) sound;
            if(sound_ !is null) {
                alSourcei(source, AL_BUFFER, sound_.buffer);
            }
        }

        protected void play_() @system {
            alSourcePlay(source);
        }

        protected void pause_() @system {
            alSourcePause(source);
        }

        protected void stop_() @system {
            alSourceStop(source);
        }
    }
}

class ALSound : Sound {
    package ALuint buffer;

    this(in string filename) @safe {
        super(filename);

        loadSound(filename);
    }

    private void loadSound(in string filename) @trusted {
        import std.exception : enforce;
        import std.file : exists;

        enforce(exists(filename), new Exception("File \"" ~ filename ~ "\" does not exist!"));

        SF_INFO info;
        SNDFILE* file = sf_open(toCString(filename), SFM_READ, &info);

        blocksound_getBackend().logger.logDebug("Loading sound " ~ filename ~ ": has " ~ to!string(info.channels) ~ " channels.");

        float[] data;
        float[] readBuf = new float[2048];
        
        long readSize = 0;
        while((readSize = sf_read_float(file, readBuf.ptr, readBuf.length)) != 0) {
            data ~= readBuf[0..(cast(size_t) readSize)];
        }

        alGenBuffers(1, &buffer);
        alBufferData(buffer, info.channels == 1 ? AL_FORMAT_MONO_FLOAT32 : AL_FORMAT_STEREO_FLOAT32, data.ptr, cast(int) (data.length * float.sizeof), info.samplerate);

        sf_close(file);
    }

    override void cleanup() @system {
        alDeleteBuffers(1, &buffer);
    }
}