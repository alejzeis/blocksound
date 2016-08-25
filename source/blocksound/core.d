module blocksound.core;

import derelict.openal.al;
import derelict.sndfile.sndfile;

public import blocksound.util;

/// Library Version
immutable string VERSION = "v1.0";

package shared bool INIT = false;

debug(blocksound_verbose) {
    private void notifyLoadLib(string lib) @safe {
        import std.stdio : writeln;
        writeln("[BlockSound]: Loaded ", lib);
    }
}

/++
    Init the library. This must be called before any other library
    features are used.
+/
void init() @trusted {
    debug(blocksound_verbose) {
        import std.stdio : writeln;
        version(blocksound_ALBackend) {
            writeln("\n[BlockSound]: BlockSound ", VERSION, " compiled with OpenAL backend.");
        }
        writeln("\n[BlockSound]: Loading libraries...");
    }

    version(blocksound_ALBackend) {
        import blocksound.backend.openal : loadLibraries;
        loadLibraries(); //TODO: skipALload, skipSFload
    } else {
        writeln("[BlockSound]: WARNING: No backend detected! Try compiling blocksound with the \"openal-backend\" configuration!");
    }

    INIT = true;

    debug(blocksound_verbose) {
        import std.stdio : writeln;
        writeln("[BlockSound]: Libraries loaded.\n");
    }
}