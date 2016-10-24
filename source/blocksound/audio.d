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
import blocksound.util;

import std.concurrency;

private void spawnAudioThread(shared AudioManager manager) @system {
    (cast(AudioManager) manager).doRun();
}

private struct SetListenerLocationMessage {
    shared Vec3 listenerLocation;
}

private struct SetGainMessage {
    shared float gain;
}

class AudioManager {
    private shared Lock listenerLock;
    private shared Lock gainLock;

    private shared Vec3 _listenerLocation;
    private shared float _gain;

    private shared Tid threadTid;

    private shared bool running;

    /// Get the location of the listener
    @property Vec3 listenerLocation() @trusted {
        synchronized(listenerLock) { 
            return _listenerLocation; 
        }
    }
    /// Set the location of the listener
    @property void listenerLocation(Vec3 listenerLocation) @trusted {
        synchronized(listenerLock) {
            this._listenerLocation = cast(shared) listenerLocation;
        }
        send(cast(Tid) threadTid, SetListenerLocationMessage(cast(shared) listenerLocation));
    }

    @property float gain() @trusted {
        synchronized(gainLock) { 
            return _gain; 
        }
    }

    @property void gain(float gain) @trusted {
        synchronized(gainLock) {
            this._gain = cast(shared) gain;
        }
        send(cast(Tid) threadTid, SetGainMessage(cast(shared) gain));
    }

    protected this(Vec3 listenerLocation, float gain) @trusted {
        listenerLock = new Lock();
        gainLock = new Lock();

        running = true;
        threadTid = cast(shared) spawn(&spawnAudioThread, cast(shared) this);

        this.listenerLocation = listenerLocation;
        this.gain = gain;
    }

    static AudioManager audioManagerFactory(Vec3 listenerLocation, float gain) @safe {
        import blocksound.backend.core : FactoryTemplate;

        mixin(FactoryTemplate!("AudioManager", "listenerLocation, gain"));
    }

    package void doRun() @system {
        debug(blocksound_debug) {
            import std.stdio : writeln;
            writeln("[BlockSound]: Starting AudioManager thread.");
        }

        while(running) {
            receive(
                (SetListenerLocationMessage m) {
                    setListenerLocation(m.listenerLocation);
                },
                (SetGainMessage m) {
                    setGain(m.gain);
                }
            );
        }

        debug(blocksound_debug) {
            import std.stdio : writeln;
            writeln("[BlockSound]: Exiting AudioManager thread.");
        }
    }

    abstract protected void setListenerLocation(Vec3 listenerLocation) @system;
    abstract protected void setGain(float gain) @system;
}