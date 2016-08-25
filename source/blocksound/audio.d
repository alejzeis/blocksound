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
import blocksound.backend.backend;

public import blocksound.backend.backend : Source, Sound;

version(blocksound_ALBackend) {
    import blocksound.backend.openal;
}

/// Manages the Audio.
class AudioManager {
    private Vec3 _listenerLocation;
    private float _gain;

    private AudioBackend backend;
    private ArrayList!Source sources;

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
        import std.exception : enforce;
        
        enforce(INIT, new Exception("BlockSound has not been initialized!"));

        version(blocksound_ALBackend) {
            backend = new ALAudioBackend();
        } else {
            throw new Exception("No backend avaliable! (Try compiling with version \"blocksound_ALBackend\" enabled)");
        }
    }

    Sound loadSoundFromFile(in string filename) {
        version(blocksound_ALBackend) {
            return ALSound.loadSound(filename);
        } else {
            throw new Exception("No backend avaliable! (Try compiling with version \"blocksound_ALBackend\" enabled)");
        }
    }

    /// Cleanup any resources used by the backend.
    void cleanup() @trusted {
        backend.cleanup();
    }
}