import java.util.HashMap;

class Module {
    // class, type, opt
    private HashMap<String, IToplevel> _privateTypes = new HashMap<>();
    private HashMap<String, IToplevel> _publicTypes = new HashMap<>();
    // def, the, let
    private HashMap<String, IToplevel> _privateWords = new HashMap<>();
    private HashMap<String, IToplevel> _publicWords = new HashMap<>();

    public Module() {
    }

    public void add(IToplevel what, boolean isPrivate) {
        switch (what.kind()) {
        case TYPE:
            if (isPrivate) {
                _privateTypes.put(what.name(), what);
            } else {
                _publicTypes.put(what.name(), what);
            }
            break;
        case WORD:
            if (isPrivate) {
                _privateWords.put(what.name(), what);
            } else {
                _publicWords.put(what.name(), what);
            }
            break;
        }
    }
}
