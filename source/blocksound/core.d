module blocksound.core;

import derelict.openal.al;
import derelict.sndfile.sndfile;

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

/// Vector 3 struct with floats.
struct Vec3 {
    /// X coordinate
    float x;
    /// Y coordinate
    float y;
    /// Z coordinate
    float z;
}

/++
    Converts a D string (immutable(char[])) to a C string
    (char*).

    Params:
            dString =   The D string to be converted.

    Returns: A C string (char array).
+/
char* toCString(in string dString) @trusted {
    import std.string : toStringz;
    return cast(char*) toStringz(dString);
}

/++
    Converts a C string (char array) to a D string
    (immutable(char[]))

    Params:
            cString =   The C string to be converted.

    Returns: A D string (immutable(char[]))
+/
string toDString(char* cString) @trusted {
    import std.string : fromStringz;
    return cast(string) fromStringz(cString);
}