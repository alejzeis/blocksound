module blocksound.backend.core;

import blocksound.util;

abstract class Backend {
    private shared BlockSoundLogger _logger;

    @property BlockSoundLogger logger() { return cast(BlockSoundLogger) _logger; }

    this(BlockSoundLogger logger) @trusted nothrow {
        this._logger = cast(shared) logger;
    }
    
    abstract void doInit() @system;
    
    abstract void doDestroy() @system;
}

template FactoryTemplate(string clazz, string parameterNames) {
    const char[] FactoryTemplate = "
        version(blocksound_ALBackend) {
            import blocksound.backend.openal : AL" ~ clazz ~ ";
            return new AL" ~ clazz ~ "(" ~ parameterNames ~ ");
        } else {
            throw new Exception(\"No backend was compiled in!\");
        }
    ";
}