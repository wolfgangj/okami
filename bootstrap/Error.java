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

    private String _get() {
        return _location + ": " + _msg;
    }

    // delegate to singleton instance
    public static void add(String msg, String location) {
        _error._add(msg, location);
    }

    public static boolean any() {
        return _error._any();
    }

    public static String get() {
        return _error._get();
    }
}
