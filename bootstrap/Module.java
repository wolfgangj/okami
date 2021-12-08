import java.util.HashMap;

class Module {
    // class, type, opt
    private HashMap<String, IDeclaration> privateTypes = new HashMap<>();
    private HashMap<String, IDeclaration> publicTypes = new HashMap<>();
    // def, the, let
    private HashMap<String, IDeclaration> privateWords = new HashMap<>();
    private HashMap<String, IDeclaration> publicWords = new HashMap<>();

    public Module() {
    }

    public void add(final IDeclaration what,
                    final boolean isPrivate) {
        switch (what.kind()) {
        case TYPE:
            Log.msg("adding " + what.name());
            if (isPrivate) {
                this.privateTypes.put(what.name(), what);
            } else {
                this.publicTypes.put(what.name(), what);
            }
            break;
        case WORD:
            Log.msg("adding " + what.name());
            if (isPrivate) {
                this.privateWords.put(what.name(), what);
            } else {
                this.publicWords.put(what.name(), what);
            }
            break;
        }
    }
}
