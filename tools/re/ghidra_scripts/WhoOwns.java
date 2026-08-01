import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.symbol.Reference;
public class WhoOwns extends GhidraScript {
  public void run() throws Exception {
    for (String a : getScriptArgs()) {
      Address ad = toAddr(Long.decode(a));
      Function f = getFunctionContaining(ad);
      println("ADDR "+ad+" in "+(f==null?"<none>":f.getName()+"@"+f.getEntryPoint()+" size="+f.getBody().getNumAddresses()));
      if (f != null) {
        for (Reference r : currentProgram.getReferenceManager().getReferencesTo(f.getEntryPoint())) {
          Function c = getFunctionContaining(r.getFromAddress());
          println("   caller "+r.getFromAddress()+" in "+(c==null?"<none>":c.getName()+"@"+c.getEntryPoint())+" "+r.getReferenceType());
        }
      }
    }
  }
}
