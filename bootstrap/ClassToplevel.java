import java.util.ArrayList;

class ClassToplevel implements IToplevel {
    private String _name;
    private ArrayList<IToplevel> _content;
    private String _pos;

    public ClassToplevel(String name, ArrayList<IToplevel> content, String pos) {
        _name = name;
        _content = content;
        _pos = pos;
    }

    public String name() {
        return _name;
    }

    public ArrayList<IToplevel> content() {
        return _content;
    }
    
    public String pos() {
        return _pos;
    }
}
