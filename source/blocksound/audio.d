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

import blocksound.backend.core;
import blocksound.core;
import blocksound.util;

import std.concurrency;

private void spawnAudioThread(shared AudioManager manager) @system {
    (cast(AudioManager) manager).doRun();
}

private struct StopThreadMessage {

}

private struct SetListenerLocationMessage {
    shared Vec3 listenerLocation;
}

private struct SetGainMessage {
    shared float gain;
}

private struct SourceSetLocationMessage {
    shared Source source;
    shared Vec3 location;
}

private struct SourceSetSoundMessage {
    shared Source source;
    shared Sound sound;
}

private enum SourceAction {
    SOURCE_PLAY,
    SOURCE_PAUSE,
    SOURCE_STOP,
    SOURCE_LOOP_TRUE,
    SOURCE_LOOP_FALSE
}

private struct SourceActionMessage {
    shared Source source;
    shared SourceAction action;
}

abstract class AudioManager {
    private shared Lock listenerLock;
    private shared Lock gainLock;

    private shared Vec3 _listenerLocation;
    private shared float _gain;

    package shared Tid threadTid;

    private shared bool running;

    /// Get the location of the listener
    @property Vec3 listenerLocation() @trusted { synchronized(listenerLock) { return _listenerLocation; } }
    /// Set the location of the listener
    @property void listenerLocation(Vec3 listenerLocation) @trusted {
        synchronized(listenerLock) {
            this._listenerLocation = cast(shared) listenerLocation;
        }
        send(cast(Tid) threadTid, SetListenerLocationMessage(cast(shared) listenerLocation));
    }

    @property float gain() @trusted { synchronized(gainLock) { return _gain; } }

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
        mixin(FactoryTemplate!("AudioManager", "listenerLocation, gain"));
    }

    package void doRun() @system {
        debug(blocksound_debug) {
            blocksound_getBackend().logger.logDebug("Entering AudioManager thread.");
        }

        while(running) {
            receive(
                (StopThreadMessage m) {
                    // TODO: Clean sources and sounds up!
                    running = false;
                },
                (SetListenerLocationMessage m) {
                    setListenerLocation(m.listenerLocation);
                },
                (SetGainMessage m) {
                    setGain(m.gain);
                },
                (SourceSetLocationMessage m) {
                    (cast(Source) m.source).setLocation(cast(Vec3) m.location);
                },
                (SourceSetSoundMessage m) {
                    (cast(Source) m.source).setSound(cast(Sound) m.sound);
                },
                (SourceActionMessage m) {
                    Source source = cast(Source) m.source;
                    final switch(m.action) {
                        case SourceAction.SOURCE_PLAY:
                            source.play_();
                            break;
                        case SourceAction.SOURCE_PAUSE:
                            source.pause_();
                            break;
                        case SourceAction.SOURCE_STOP:
                            source.stop_();
                            break;
                        case SourceAction.SOURCE_LOOP_TRUE:
                        case SourceAction.SOURCE_LOOP_FALSE:
                            // TODO!
                            break;
                    }
                }
            );
        }

        doCleanup();

        debug(blocksound_debug) {
            blocksound_getBackend().logger.logDebug("Exiting AudioManager thread.");
        }
    }

    void stopThread() @trusted {
        send(cast(Tid) threadTid, StopThreadMessage());
    }

    abstract protected void setListenerLocation(Vec3 listenerLocation) @system;
    abstract protected void setGain(float gain) @system;
    abstract protected void doCleanup() @system;
}

abstract class Source {
    private shared Lock locationLock;
    private shared Lock soundLock;

    private shared AudioManager _manager;

    private shared Vec3 _location;
    private shared Sound _sound;

    @property AudioManager manager() @trusted nothrow { return cast(AudioManager) _manager; }

    @property Vec3 location() @trusted { synchronized(locationLock) { return cast(Vec3) _location; } }
    @property void location(Vec3 location) @trusted { 
        synchronized(locationLock) {
            this._location = cast(shared) location;
        }
        send(cast(Tid) manager.threadTid, SourceSetLocationMessage(cast(shared) this, this._location));
    }

    @property Sound sound() @trusted { synchronized(soundLock) { return cast(Sound) _sound; } }
    @property void sound(Sound sound) @trusted {
        synchronized(soundLock) {
            this._sound = cast(shared) sound;
        }
        send(cast(Tid) manager.threadTid, SourceSetSoundMessage(cast(shared) this, this._sound));
    }

    protected this(AudioManager manager, Vec3 location) @trusted {
        this._manager = cast(shared) manager;
        this.location = location;
    }

    static Source sourceFactory(AudioManager manager, Vec3 location) @safe {
        mixin(FactoryTemplate!("Source", "manager, location"));
    }

    void play() @trusted {
        send(cast(Tid) manager.threadTid, SourceActionMessage(cast(shared) this, SourceAction.SOURCE_PLAY));
    }

    void pause() @trusted {
        send(cast(Tid) manager.threadTid, SourceActionMessage(cast(shared) this, SourceAction.SOURCE_PAUSE));
    }

    void stop() @trusted {
        send(cast(Tid) manager.threadTid, SourceActionMessage(cast(shared) this, SourceAction.SOURCE_STOP));
    }

    abstract protected void setLocation(Vec3 location) @system;
    abstract protected void setSound(Sound sound) @system;
    abstract protected void play_() @system;
    abstract protected void pause_() @system;
    abstract protected void stop_() @system;
}

abstract class Sound {
    /// The filename from which the sound was loaded.
    immutable string filename;

    protected this(in string filename) @safe nothrow {
        this.filename = filename;
    }

    static Sound soundFactory(in string filename) @safe {
        mixin(FactoryTemplate!("Sound", "filename"));
    }

    abstract void cleanup() @system;
}