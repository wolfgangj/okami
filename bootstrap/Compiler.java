import java.io.FileNotFoundException;
import java.util.List;
import java.util.ArrayList;

class Compiler {
    private String _moduleName;
    private Parser _parser;
    private int _nextLabel = 0;
    private List<Integer> _loopEndLabels = new ArrayList<>();

    private Module _module = new Module();
    private List<Module> _imports = new ArrayList<>();

    public Compiler(String moduleName)
        throws FileNotFoundException {

        _moduleName = moduleName;
        _parser = new Parser(moduleName + ".wok");
        pass1();
        pass2();
    }

    private void pass1() {
        boolean isPrivate = false;
        for (var next = _parser.nextDeclaration();
             next.isPresent();
             next = _parser.nextDeclaration()) {
            var tl = next.get();
            switch (tl.kind()) {
            case WORD:
            case TYPE:
                _module.add(tl, isPrivate);
                break;
            case IMPORT:
                // TODO
                break;
            case VPUBLIC:
                isPrivate = false;
                break;
            case VPRIVATE:
                isPrivate = true;
                break;
            }
        }
    }

    private void pass2() {

    }
}
