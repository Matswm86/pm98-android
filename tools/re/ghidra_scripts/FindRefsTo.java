import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.symbol.ReferenceManager;
import ghidra.program.model.listing.Function;

public class FindRefsTo extends GhidraScript {
  public void run() throws Exception {
    String[] args = getScriptArgs();
    for (String a : args) {
      long addr = Long.decode(a);
      Address target = toAddr(addr);
      ReferenceManager rm = currentProgram.getReferenceManager();
      for (Reference r : rm.getReferencesTo(target)) {
        Address from = r.getFromAddress();
        Function fn = getFunctionContaining(from);
        String fnName = fn==null?"<none>":fn.getName()+"@"+fn.getEntryPoint();
        println("REF to "+target+" from "+from+" in "+fnName+" type="+r.getReferenceType());
      }
    }
  }
}
