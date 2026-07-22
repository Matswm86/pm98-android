// Find functions that BOTH (a) read a player attr byte [reg+0x9c..0x9f] and
// (b) contain an FMUL/FIMUL/FMULP. That is the market fee/wage compute signature
// (value = f(core4/attrs) x club_stature). Reports each such function once with
// the attr-read and fmul sites. Also flags functions that call the core4 helper
// FUN_00534570 AND fmul.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.AddressSetView;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.Listing;

public class FindAttrFmul extends GhidraScript {
    @Override
    public void run() throws Exception {
        Listing listing = currentProgram.getListing();
        FunctionManager fm = currentProgram.getFunctionManager();
        String[] attrToks = {"0x9c]", "0x9d]", "0x9e]", "0x9f]"};
        int reported = 0;
        for (Function f : fm.getFunctions(true)) {
            AddressSetView body = f.getBody();
            boolean hasFmul = false, hasAttr = false, callsCore4 = false;
            String attrSite = "", fmulSite = "";
            for (Instruction ins : listing.getInstructions(body, true)) {
                String m = ins.getMnemonicString().toUpperCase();
                if (m.equals("FMUL") || m.equals("FIMUL") || m.equals("FMULP")) {
                    hasFmul = true; if (fmulSite.isEmpty()) fmulSite = ins.getAddress() + " " + ins;
                }
                if (m.equals("CALL")) {
                    String t = ins.getDefaultOperandRepresentation(0);
                    if (t != null && t.contains("00534570")) callsCore4 = true;
                }
                for (int op = 0; op < ins.getNumOperands(); op++) {
                    String r = ins.getDefaultOperandRepresentation(op);
                    if (r == null) continue;
                    String rl = r.toLowerCase();
                    for (String tok : attrToks) {
                        if (rl.contains(tok) && rl.contains("[")) {
                            hasAttr = true; if (attrSite.isEmpty()) attrSite = ins.getAddress() + " " + ins;
                        }
                    }
                }
            }
            if (hasFmul && (hasAttr || callsCore4)) {
                println(String.format("CANDIDATE fn=%s  fmul[%s]  attr[%s]  core4call=%b",
                        f.getEntryPoint(), fmulSite, attrSite.isEmpty() ? "-" : attrSite, callsCore4));
                reported++;
            }
        }
        println("FindAttrFmul: " + reported + " candidate functions");
    }
}
