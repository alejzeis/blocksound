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