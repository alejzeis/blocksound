module blocksound.backend.openal;

import blocksound.audio;
import blocksound.util;
import blocksound.backend.core;

import derelict.openal.al;

class ALBackend : Backend {
    override {
        void doInit() @system {
            
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
}