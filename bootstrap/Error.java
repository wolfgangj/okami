class Error {
    static private Error error = new Error();

    private String msg = null;
    private String location = null;

    private Error() {
    }

    private void _add(String msg, String location) {
        if (any()) { // previous error found
            return;
        }
        this.msg = msg;
        this.location = location;
    }

    private boolean _any() {
        return this.msg != null;
    }

    private String _fetch() {
        final var result = this.location + ": " + this.msg;
        this.location = null;
        this.msg = null;
        return result;
    }

    // delegate to singleton instance
    public static void add(final String msg,
                           final String location) {
        error._add(msg, location);
    }

    public static boolean any() {
        return error._any();
    }

    public static String fetch() {
        return error._fetch();
    }

    public static void trace(final String msg) {
        System.err.println(msg);
    }
}
