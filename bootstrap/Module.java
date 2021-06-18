import java.util.HashMap;

class Module {
    // class, type, opt
    private HashMap<String, IToplevel> _privateTypes = new HashMap<>();
    private HashMap<String, IToplevel> _publicTypes = new HashMap<>();
    // def, the
    private HashMap<String, IToplevel> _privateWords = new HashMap<>();
    private HashMap<String, IToplevel> _publicWords = new HashMap<>();

    public Module() {
    }

    public void add(IToplevel what, boolean isPrivate) {
        
    }
}
