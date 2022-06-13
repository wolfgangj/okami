import java.io.FileNotFoundException;
import java.util.List;
import java.util.ArrayList;
import java.util.HashMap;

class ModuleCompiler {
    private String moduleName;
    private Parser parser;
    private int nextLabel = 0;
    private List<Integer> loopEndLabels = new ArrayList<>();

    private Module module = new Module();
    private List<Module> imports = new ArrayList<>();
    private HashMap<String, ModuleCompiler> units;

    public ModuleCompiler(final String moduleName,
                    final HashMap<String, ModuleCompiler> units)
        throws FileNotFoundException {

        Log.msg("compiling " + moduleName);
        Log.sub(() -> {
                this.moduleName = moduleName;
                this.parser = new Parser(moduleName + ".wok");
                this.units = units;

                this.units.put(this.moduleName, this);
                pass1();
            });
    }

    private void pass1()
        throws FileNotFoundException {

        boolean isPrivate = false;
        for (var next = this.parser.nextDeclaration();
             next.isPresent();
             next = this.parser.nextDeclaration()) {
            var tl = next.get();
            switch (tl.kind()) {
            case WORD:
            case TYPE:
                this.module.add(tl, isPrivate);
                break;
            case IMPORT:
                var use = (UseDeclaration) tl;
                if (this.units.containsKey(use.name())) {
                    break;
                }
                var compiler = new ModuleCompiler(use.name(), this.units);
                this.imports.add(compiler.module);
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

    public void codegen() {
        Log.msg("codegen for " + this.moduleName);
        Log.sub(() -> {
                pass2();
            });
    }

    private void pass2() {
        pass2For(module.getPublicWords());
        pass2For(module.getPrivateWords());
    }

    private void pass2For(final HashMap<String, IDeclaration> words) {
        for (final var name : words.keySet()) {
            if (Error.any()) {
                return;
            }
            codegenForWord(name, words.get(name));
        }
    }

    private void codegenForWord(final String name, final IDeclaration word) {
        Log.msg("codegen for word: " + name);
        // TODO
        //switch (word.kind()) {
        //    case WORD:
        //}
    }
}
