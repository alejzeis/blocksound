module blocksound.sound;

import blocksound.core;
import blocksound.backend.backend;

version(blocksound_ALBackend) {
    import blocksound.backend.openal;
}

/// Manages the Audio.
class AudioManager {
    private Vec3 _listenerLocation;
    private float _gain;

    private Backend backend;

    /// The location where the listener is.
    @property Vec3 listenerLocation() @safe nothrow { return _listenerLocation; }
    /// The location where the listener is.
    @property void listenerLocation(Vec3 loc) @safe nothrow {
        _listenerLocation = loc; 
        backend.setListenerLocation(loc); 
    }

    /// The listener's gain or volume.
    @property float gain() @safe nothrow { return _gain; }
    /// The listener's gain or volume.
    @property void gain(float gain) @safe nothrow {
        _gain = gain;
        backend.setListenerGain(gain);
    }

    /++

    +/
    this() {
        
    }
}