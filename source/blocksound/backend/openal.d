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

        }

        protected void setGain(float gain) @system {

        }
    }
}