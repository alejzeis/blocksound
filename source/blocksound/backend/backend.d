module blocksound.backend.backend;

import blocksound.core;

/// Base class for backends.
abstract class Backend {
    
    abstract void setListenerLocation(Vec3 loc) @trusted;

    abstract void setListenerGain(float gain) @trusted;
}