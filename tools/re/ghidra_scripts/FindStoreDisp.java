// Headless GhidraScript: find every instruction that WRITES a memory operand with
// a given displacement (default 0x74), including x87 float stores (FSTP/FST) that
// the MOV-only scanners miss. Prints containing function + VA + full instruction.
// Args: [<dispHex>]   e.g. 0x74
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.Listing;

public class FindStoreDisp extends GhidraScript {
    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        String disp = (args.length >= 1) ? args[0].toLowerCase() : "0x74";
        String needle1 = "+ " + disp + "]";
        String needle2 = "+" + disp + "]";
        Listing listing = currentProgram.getListing();
        var fm = currentProgram.getFunctionManager();
        int n = 0;
        for (Instruction ins : listing.getInstructions(true)) {
            String m = ins.getMnemonicString().toUpperCase();
            boolean store = m.startsWith("MOV") || m.equals("FSTP") || m.equals("FST")
                    || m.equals("FISTP") || m.equals("FIST") || m.equals("ADD")
                    || m.equals("SUB") || m.equals("AND") || m.equals("OR")
                    || m.equals("INC") || m.equals("DEC") || m.equals("XOR");
            if (!store) continue;
            // destination for these forms is operand 0
            String op0 = ins.getDefaultOperandRepresentation(0);
            if (op0 == null) continue;
            String o = op0.toLowerCase();
            if (!(o.contains(needle1) || o.contains(needle2))) continue;
            if (!o.contains("[")) continue;   // must be a memory operand
            Function f = fm.getFunctionContaining(ins.getAddress());
            String fn = (f != null) ? f.getEntryPoint().toString() : "??";
            println(String.format("%s  fn=%s  %s %s", ins.getAddress(), fn,
                    ins.getMnemonicString(), ins.toString()));
            n++;
        }
        println("# total stores to disp " + disp + ": " + n);
    }
}
