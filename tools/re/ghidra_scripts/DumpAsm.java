import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.InstructionIterator;

public class DumpAsm extends GhidraScript {
  public void run() throws Exception {
    String[] a=getScriptArgs();
    long start=Long.decode(a[0]); long end=Long.decode(a[1]);
    Address s=toAddr(start), e=toAddr(end);
    InstructionIterator it=currentProgram.getListing().getInstructions(s,true);
    while(it.hasNext()){ Instruction in=it.next(); if(in.getAddress().compareTo(e)>0) break;
      println(in.getAddress()+": "+in.toString()); }
  }
}
