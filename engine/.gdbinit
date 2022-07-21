define hook-stop
  x/1i $pc
end
alias da=disassemble
alias reg=info registers

set disassembly-flavor intel
break _start
run
