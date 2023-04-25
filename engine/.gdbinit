define hook-stop
  x/1i $pc
end
alias da=disassemble
alias reg=info registers
define pos
  print (char*)$r12-8
end

set disassembly-flavor intel
break _start
run
