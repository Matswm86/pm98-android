// Headless GhidraScript: find instructions whose DESTINATION (operand 0) memory
// operand contains a given token — catches MOV/ADD/INC/DEC/OR/... stores that
// FindDwordStore's MOV-only scan misses. Token examples: "0x224]" (field disp),
// "[0x66b1e8]" (global). Args: <token> [<token> ...]
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.Listing;

public class ScanWrites extends GhidraScript {

    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        if (args.length < 1) {
            println("ScanWrites: need <token> [...]");
            return;
        }
        Listing listing = currentProgram.getListing();
        int n = 0;
        for (Instruction ins : listing.getInstructions(true)) {
            // operand 0 is the destination for the x86 write forms we care about
            if (ins.getNumOperands() < 1) {
                continue;
            }
            String m = ins.getMnemonicString().toUpperCase();
            boolean writes = m.startsWith("MOV") || m.equals("ADD") || m.equals("SUB")
                    || m.equals("INC") || m.equals("DEC") || m.equals("OR") || m.equals("AND")
                    || m.equals("XOR") || m.equals("NOT") || m.equals("NEG");
            if (!writes) {
                continue;
            }
            String dst = ins.getDefaultOperandRepresentation(0).toLowerCase();
            if (!dst.contains("[")) {
                continue;
            }
            for (String tok : args) {
                if (dst.contains(tok.toLowerCase())) {
                    Function f = getFunctionContaining(ins.getAddress());
                    String fn = f == null ? "<none>" : f.getName() + "@" + f.getEntryPoint();
                    println("WRITE " + ins.getAddress() + "  " + ins + "   in " + fn);
                    n++;
                    break;
                }
            }
        }
        println("ScanWrites: " + n + " hits");
    }
}
