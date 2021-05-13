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
*/

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

        // Interfaces
        Type t = new AdrType(new BasicType("int"));
        System.err.println(t.toString());

        // Token
        var tok = new Token(Token.Kind.INT, "26", "/dev/null", 42);
        System.err.println(tok.toString());

        // Lexer
        var lex = new Lexer("/dev/stdin");
        lex.nextToken();
        System.err.println(lex.line());
    }
}
