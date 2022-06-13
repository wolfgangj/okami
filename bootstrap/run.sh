rm -f Wok.class
javac *.java 2>&1 | head -n 8
if [ -e Wok.class ]; then java Wok test; fi
