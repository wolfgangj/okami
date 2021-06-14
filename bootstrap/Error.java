class Error {
    static private Error _error = new Error();

    private String _msg = null;
    private String _location = null;

    private Error() {
    }

    private void _add(String msg, String location) {
        if (any()) { // previous error found
            return;
        }
        _msg = msg;
        _location = location;
    }

    private boolean _any() {
        return _msg != null;
    }

    private String _fetch() {
        var result = _location + ": " + _msg;
        _location = null;
        _msg = null;
        return result;
    }

    // delegate to singleton instance
    public static void add(String msg, String location) {
        _error._add(msg, location);
    }

    public static boolean any() {
        return _error._any();
    }

    public static String fetch() {
        return _error._fetch();
    }

    public static void trace(String msg) {
        System.err.println(msg);
    }
}
