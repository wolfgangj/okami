rm -f classes/Wok.class
mkdir -p classes
javac -d ./classes *.java 2>&1 | head -n 8
if [ -e classes/Wok.class ]; then cd classes && java Wok test; fi
