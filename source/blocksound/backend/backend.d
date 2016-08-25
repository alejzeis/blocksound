module blocksound.backend.backend;

import blocksound.core;

/// Base class for the audio backend.
abstract class AudioBackend {
    
    abstract void setListenerLocation(in Vec3 loc) @trusted;

    abstract void setListenerGain(in float gain) @trusted;

    abstract void cleanup() @trusted;
}

/// Represents a source that emits audio.
abstract class Source {
    protected Vec3 _location;
    protected Sound sound;

    /// The location of the source.
    @property Vec3 location() @safe nothrow { return _location; }
    /// The location of the source.
    @property void location(Vec3 loc) @safe nothrow {
        _location = loc;
    }

    /++
        Create a new source. The backend class will automatically be
        determined.

        Returns: A new Source instance.
    +/
    static Source newSource(Vec3 location) {
        version(blocksound_ALBackend) {
            import blocksound.backend.openal : ALSource;

            Source source = new ALSource();
            source.location = location;
            return source;
        } else {
            throw new Exception("No backend avaliable! (Try compiling with version \"blocksound_ALBackend\" enabled)");
        }
    }
    
    final void setSound(Sound sound) @trusted {
        this.sound = sound;
        _setSound(sound);
    }

    protected abstract void _setSound(Sound sound) @trusted;

    abstract void play() @trusted;

    abstract void stop() @trusted;

    abstract bool hasFinishedPlaying() @trusted;

    final void cleanup() @trusted {
        sound.cleanup();
        _cleanup();
    }

    abstract protected void _cleanup();
}

/++
    Represents a sound, loaded in memory. For
    larger sounds, consider using streaming instead.

    TODO: STREAMING
+/
interface Sound {

    /// Frees resources used by the sound.
    void cleanup() @trusted;
}