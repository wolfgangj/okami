import java.util.ArrayList;

class OptDeclaration implements IDeclaration {
    private final String name;
    private final ArrayList<String> options;
    private final String pos;

    public OptDeclaration(final String name,
                          final ArrayList<String> options,
                          final String pos) {
        this.name = name;
        this.options = options;
        this.pos = pos;
    }

    public String name() {
        return this.name;
    }

    public ArrayList<String> options() {
        return this.options;
    }
    
    public String pos() {
        return this.pos;
    }

    public Kind kind() {
        return IDeclaration.Kind.TYPE;
    }
}
