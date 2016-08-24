module blocksound.backend.backend;

import blocksound.core;

/// Base class for the audio backend.
abstract class AudioBackend {
    
    abstract void setListenerLocation(in Vec3 loc) @trusted;

    abstract void setListenerGain(in float gain) @trusted;
}

/// Represents a source that emits audio.
abstract class Source {
    protected Vec3 _location;
    protected ArrayList!Sound sounds;

    /// The location of the source.
    @property Vec3 location() @safe nothrow { return _location; }
    /// The location of the source.
    @property void location(Vec3 loc) @safe nothrow {
        _location = loc;
    }
    
    abstract void addSound(Sound sound) @trusted;

    final void cleanup() @trusted {
        foreach(sound; (cast(shared) sounds).array) {
            sound.cleanup();
        }
        _cleanup();
    }

    abstract protected void _cleanup();
}

/++
    Represents a sound, loaded in memory. For
    larger sounds, consider using streaming instead.

    TODO: STREAMING
+/
abstract class Sound {

    /// Frees resources used by the sound.
    abstract void cleanup() @trusted;
}