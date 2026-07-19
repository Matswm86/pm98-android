// Find LEA reg,[base+disp] sites (default disp 0x74) and report whether an FSTP/FST
// (float store) occurs within the next 12 instructions using that register -> the
// float-write-via-computed-pointer idiom that displacement scans miss.
// Args: [<dispHex>]
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.Listing;

public class FindLeaFstp extends GhidraScript {
    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        String disp = (args.length >= 1) ? args[0].toLowerCase() : "0x74";
        String n1 = "+ " + disp + "]", n2 = "+" + disp + "]";
        Listing listing = currentProgram.getListing();
        var fm = currentProgram.getFunctionManager();
        for (Instruction ins : listing.getInstructions(true)) {
            if (!ins.getMnemonicString().equalsIgnoreCase("LEA")) continue;
            String op1 = ins.getDefaultOperandRepresentation(1);
            if (op1 == null) continue;
            String o = op1.toLowerCase();
            if (!(o.contains(n1) || o.contains(n2))) continue;
            String reg = ins.getDefaultOperandRepresentation(0);
            // look ahead up to 12 instructions for a float store or int store via reg
            Instruction nx = ins.getNext();
            String found = "";
            for (int i = 0; i < 12 && nx != null; i++) {
                String m = nx.getMnemonicString().toUpperCase();
                String d0 = nx.getDefaultOperandRepresentation(0);
                if (d0 == null) d0 = "";
                if ((m.equals("FSTP") || m.equals("FST") || m.startsWith("MOV") || m.equals("FISTP"))
                        && d0.toLowerCase().contains("[" + reg.toLowerCase())) {
                    found = nx.getAddress() + " " + nx.toString();
                    break;
                }
                nx = nx.getNext();
            }
            Function f = fm.getFunctionContaining(ins.getAddress());
            String fn = (f != null) ? f.getEntryPoint().toString() : "??";
            println(String.format("LEA@%s fn=%s  %s  -> store: %s", ins.getAddress(), fn,
                    ins.toString(), found.isEmpty() ? "(none nearby)" : found));
        }
    }
}
