module blocksound.backend.core;

abstract class Backend {
    
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