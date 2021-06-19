import java.util.ArrayList;

class OptDeclaration implements IDeclaration {
    private String _name;
    private ArrayList<String> _options;
    private String _pos;

    public OptDeclaration(String name, ArrayList<String> options, String pos) {
        _name = name;
        _options = options;
        _pos = pos;
    }

    public String name() {
        return _name;
    }

    public ArrayList<String> options() {
        return _options;
    }
    
    public String pos() {
        return _pos;
    }

    public Kind kind() {
        return IDeclaration.Kind.TYPE;
    }
}
