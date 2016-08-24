module blocksound.audio;

import blocksound.core;
import blocksound.backend.backend;

version(blocksound_ALBackend) {
    import blocksound.backend.openal;
}

alias AudioSource = blocksound.backend.backend.Source;

/// Manages the Audio.
class AudioManager {
    private Vec3 _listenerLocation;
    private float _gain;

    private AudioBackend backend;
    private ArrayList!AudioSource sources;

    /// The location where the listener is.
    @property Vec3 listenerLocation() @safe nothrow { return _listenerLocation; }
    /// The location where the listener is.
    @property void listenerLocation(Vec3 loc) @safe {
        _listenerLocation = loc; 
        backend.setListenerLocation(loc); 
    }

    /// The listener's gain or volume.
    @property float gain() @safe nothrow { return _gain; }
    /// The listener's gain or volume.
    @property void gain(float gain) @safe {
        _gain = gain;
        backend.setListenerGain(gain);
    }

    /++
        Initializes the AudioManager and it's backend.
        Backend is decided at compile-time.
    +/
    this() @trusted {
        version(blocksound_ALBackend) {
            backend = new ALAudioBackend();
        } else {
            throw new Exception("No backend avaliable! (Try compiling with version \"blocksound_ALBackend\" enabled)");
        }
    }


}