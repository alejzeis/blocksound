module blocksound.backend.core;

abstract class Backend {
    
    abstract void doInit() @system;
    
    abstract void doDestroy() @system;
}