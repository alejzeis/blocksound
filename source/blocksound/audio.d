/*
 *  zlib License
 *  
 *  (C) 2016 jython234
 *  
 *  This software is provided 'as-is', without any express or implied
 *  warranty.  In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *  
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, subject to the following restrictions:
 *  
 *  1. The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  2. Altered source versions must be plainly marked as such, and must not be
 *     misrepresented as being the original software.
 *  3. This notice may not be removed or altered from any source distribution.
*/
module blocksound.audio;

import blocksound.core;
import blocksound.backend.types;

public import blocksound.backend.types : Source, Sound, StreamingSource, StreamedSound;

version(blocksound_ALBackend) {
    import blocksound.backend.openal;
}

class Lock {

}

/++
    Loads a Sound from a file.

    Params:
            file =  The file where the sound is stored.

    Returns: A Sound instance loaded from the specified file.
+/
Sound loadSoundFile(in string file) @trusted {
    version(blocksound_ALBackend) {
        import blocksound.backend.openal : ALSound;

        return ALSound.loadSound(file);
    } else {
        throw new Exception("No backend avaliable! (Try compiling with version \"blocksound_ALBackend\" enabled)");
    }
}

/++
    Loads a Sound from a file for streaming.

    Params:
            file =  The file where the sound is stored.

    Returns: A StreamedSound instance loaded from the specified file.
+/
StreamedSound loadStreamingSoundFile(in string file, in size_t numBuffers = 4) @trusted {
    version(blocksound_ALBackend) {
        import blocksound.backend.openal : ALStreamedSound;
        import derelict.openal.al : ALuint;

        return ALStreamedSound.loadSound(file, cast(ALuint) numBuffers);
    } else {
        throw new Exception("No backend avaliable! (Try compiling with version \"blocksound_ALBackend\" enabled)");
    }
}

/// Manages the Audio.
class AudioManager {
    private shared Lock listenerLock;
    private shared Lock gainLock;

    private shared Vec3 _listenerLocation;
    private shared float _gain;

    private AudioBackend backend;
    private shared ArrayList!Source sources;

    /// The location where the listener is.
    @property Vec3 listenerLocation() @trusted {
        synchronized(listenerLock) { 
            return cast(Vec3) _listenerLocation;
        } 
    }
    /// The location where the listener is.
    @property void listenerLocation(Vec3 loc) @safe {
        synchronized(listenerLock) {
            _listenerLocation = cast(shared) loc; 
            backend.setListenerLocation(loc);
        } 
    }

    /// The listener's gain or volume.
    @property float gain() @trusted {
        synchronized(gainLock) { 
            return cast(shared) _gain;
        } 
    }
    /// The listener's gain or volume.
    @property void gain(float gain) @safe {
        synchronized(gainLock) {
            _gain = cast(shared) gain;
            backend.setListenerGain(gain);
        }
    }

    /++
        Initializes the AudioManager and it's backend.
        Backend is decided at compile-time.
    +/
    this() @trusted {
        import std.exception : enforce;
        
        enforce(INIT, new Exception("BlockSound has not been initialized!"));

        version(blocksound_ALBackend) {
            backend = new ALAudioBackend();
        } else {
            throw new Exception("No backend avaliable! (Try compiling with version \"blocksound_ALBackend\" enabled)");
        }

        listenerLock = new Lock();
        gainLock = new Lock();

        sources = new ArrayList!Source();
    }

    /++
        Create a a new Source at the specified
        location. The Source is also added to this AudioManager.

        Params:
                location =  The location of the Source.

        Returns: A new Source.
    +/
    Source createSource(Vec3 location) @trusted {
        Source source = backend_createSource(location);
        sources.add(source);
        return source;
    }

    /++
        Create a a new StreamingSource at the specified
        location. The Source is also added to this AudioManager.
        This is for Streaming sounds.

        Params:
                location =  The location of the Source.

        Returns: A new Source.
    +/
    StreamingSource createStreamingSource(Vec3 location) @trusted {
        StreamingSource source = backend_createStreamingSource(location);
        sources.add(source);
        return source;
    }

    /++
        Deletes a Source, frees it's resources,
        and removes it from the AudioManager.

        Params:
                source =    The source to be deleted.
    +/
    void deleteSource(Source source) @trusted {
        sources.remove(source);
        source.cleanup();
    }

    /// Cleanup any resources used by the backend.
    void cleanup() @trusted {
        backend.cleanup();
    }
}