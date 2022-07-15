class Log {
    private static int level = 0;
    private static boolean enabled;

    public static void enable() {
        enabled = true;
    }

    public static void disable() {
        enabled = false;
    }

    public static
        <E1 extends Throwable, E2 extends Throwable, E3 extends Throwable>
        void sub(final ThrowingRunnable<E1, E2, E3> thunk)
        throws E1, E2, E3
    {
        level++;
        try {
            thunk.run();
        } finally {
            level--;
        }
    }

    public static void msg(final String text) {
        if (!enabled) {
            return;
        }

        for (int i = 0; i < level; i++) {
            System.err.print("  ");
        }
        System.err.println(text);
    }

    @FunctionalInterface
    public interface ThrowingRunnable
        <E1 extends Throwable, E2 extends Throwable, E3 extends Throwable> {
        public void run()
            throws E1, E2, E3;
    }
}
