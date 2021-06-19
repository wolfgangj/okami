import java.util.ArrayList;

class ClassDeclaration implements IDeclaration {
    private String _name;
    private ArrayList<IDeclaration> _content;
    private String _pos;

    public ClassDeclaration(String name, ArrayList<IDeclaration> content, String pos) {
        _name = name;
        _content = content;
        _pos = pos;
    }

    public String name() {
        return _name;
    }

    public ArrayList<IDeclaration> content() {
        return _content;
    }
    
    public String pos() {
        return _pos;
    }

    public Kind kind() {
        return IDeclaration.Kind.TYPE;
    }
}
