import java.io.*;
import java.util.HashMap;
import java.util.ArrayList;

class Wok
{
    public static void main(String args[])
    throws IOException, FileNotFoundException {
        System.err.println("Wok 0.4-pre");

        if (args.length != 1) {
            System.err.println("usage: wok file.wok");
            return;
        }
/*
        var in = new FileInputStream(args[0]);
        var out = new PrintStream("test2.txt");
        out.println("Hello");

        int c;
        while ((c = in.read()) != -1) {
            out.println(c);
        }

        // HashMap
        var map = new HashMap<String, Integer>();
        map.put("hi", 14);
        map.put("answer", 42);
        System.err.println(map.get("answer"));

        for (var key : map.keySet()) {
            System.err.println(key + ":" + map.get(key));
        }

        // ArrayList
        var list = new ArrayList<String>();
        list.add("ah");
        list.add("ra");
        list.add("pa");
        list.add("ca");
        list.add("na");
        for (var syl : list) {
            System.err.println(syl);
        }

        // Lexer
        var lex = new Lexer("/dev/stdin");
        lex.nextToken();
        System.err.println(lex.line());
        var parser = new Parser("/dev/stdin");
        parser.nextDeclaration();
*/
        Log.enable();

        final var units = new HashMap<String, ModuleCompiler>();
        ModuleCompiler compiler = new ModuleCompiler("app", units);
        
        if (Error.any()) {
            System.err.println(Error.fetch());
            return;
        }

        for (final var unit : units.values()) {
            unit.codegen();
        }
        
        if (Error.any()) {
            System.err.println(Error.fetch());
        }
    }
}
