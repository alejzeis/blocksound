module blocksound.core;

import derelict.openal.al;
import derelict.sndfile.sndfile;

public import blocksound.util;

package shared bool INIT = false;

debug(blocksound_verbose) {
    private void notifyLoadLib(string lib) @safe @nogc {
        import std.stdio : writeln;
        writeln("[BlockSound]: Loaded ", lib);
    }
}

/++
    Init the library. This must be called before any other library
    features are used.

    Params:
            skipALload =    Skips loading OpenAL from derelict.
                            Set this to true if your application loads
                            OpenAL itself before blocksound does.

            skipSFLoad =    Skips loading libsndfile from derelict.
                            Set this to true if your application loads
                            libsdnfile itself before blocksound does.
+/
void init(in bool skipALload = false, in bool skipSFLoad = false) @trusted {
    debug(blocksound_verbose) {
        import std.stdio : writeln;
        writeln("\n[BlockSound]: Loading libraries...");
    }
    
    if(!skipALload) {
        version(Windows) {
            try {
                DerelictAL.load(); // Search for system libraries first.
                debug(blocksound_verbose) notifyLoadLib("OpenAL");
            } catch(Exception e) {
                DerelictAL.load("lib\\openal32.dll"); // Try to use provided library.
                debug(blocksound_verbose) notifyLoadLib("OpenAL");
            }
        } else {
            DerelictAL.load();
            debug(blocksound_verbose) notifyLoadLib("OpenAL");
        }
    }

    if(!skipSFLoad) {
        version(Windows) {
            try {
                DerelictSndFile.load(); // Search for system libraries first.
                debug(blocksound_verbose) notifyLoadLib("libsndfile");
            } catch(Exception e) {
                DerelictSndFile.load("lib\\libsndfile-1.dll"); // Try to use provided library.
                debug(blocksound_verbose) notifyLoadLib("libsndfile");
            }
        } else {
            DerelictSndFile.load();
            debug(blocksound_verbose) notifyLoadLib("libsndfile");
        }
    }

    INIT = true;

    debug(blocksound_verbose) {
        import std.stdio : writeln;
        writeln("[BlockSound]: Libraries loaded.\n");
    }
}