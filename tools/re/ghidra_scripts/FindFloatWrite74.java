// For every FSTP/FST/FISTP float-store, walk BACKWARD up to 20 instructions to
// find where its destination register was set to base+disp (LEA reg,[b+disp] or
// ADD reg,disp or LEA reg,[b+reg]). Catches the add-based +0x74 wage-write idiom
// that FindLeaFstp's forward-only, lea-only scan misses.
// Args: [<dispHex>]   default 0x74
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.Listing;

public class FindFloatWrite74 extends GhidraScript {
    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        String disp = (args.length >= 1) ? args[0].toLowerCase() : "0x74";
        Listing listing = currentProgram.getListing();
        var fm = currentProgram.getFunctionManager();
        int hits = 0;
        for (Instruction ins : listing.getInstructions(true)) {
            String m = ins.getMnemonicString().toUpperCase();
            if (!(m.equals("FSTP") || m.equals("FST") || m.equals("FISTP"))) continue;
            String d0 = ins.getDefaultOperandRepresentation(0);
            if (d0 == null || !d0.contains("[")) continue;
            String d = d0.toLowerCase();
            // Case 1: direct displacement float store [reg + 0x74]
            boolean direct = d.contains("+ " + disp + "]") || d.contains("+" + disp + "]");
            // extract dest register inside [ ]
            String reg = "";
            int lb = d.indexOf('['); int plus = d.indexOf('+', lb); int rb = d.indexOf(']', lb);
            if (lb >= 0 && rb > lb) {
                String inside = (plus > lb && plus < rb) ? d.substring(lb+1, plus) : d.substring(lb+1, rb);
                reg = inside.trim();
            }
            String origin = "";
            if (!direct && !reg.isEmpty()) {
                Instruction pv = ins.getPrevious();
                for (int i = 0; i < 20 && pv != null; i++) {
                    String pm = pv.getMnemonicString().toUpperCase();
                    String p0 = pv.getDefaultOperandRepresentation(0);
                    if (p0 != null && p0.trim().equalsIgnoreCase(reg)) {
                        String p1 = pv.getNumOperands() > 1 ? pv.getDefaultOperandRepresentation(1) : "";
                        if (p1 == null) p1 = "";
                        String pl = p1.toLowerCase();
                        if ((pm.equals("LEA") && (pl.contains("+ " + disp + "]") || pl.contains("+" + disp + "]")))
                            || (pm.equals("ADD") && pl.equals(disp))) {
                            origin = pv.getAddress() + " " + pv.toString();
                            break;
                        }
                        // register overwritten by something else -> stop (value clobbered)
                        if (pm.equals("MOV") || pm.equals("LEA") || pm.equals("POP") || pm.equals("XOR")) break;
                    }
                    pv = pv.getPrevious();
                }
            }
            if (direct || !origin.isEmpty()) {
                Function f = fm.getFunctionContaining(ins.getAddress());
                String fn = (f != null) ? f.getEntryPoint().toString() : "??";
                println(String.format("FLOATWRITE@%s fn=%s  %s  %s", ins.getAddress(), fn,
                        ins.toString(), direct ? "(direct +"+disp+")" : ("<- "+origin)));
                hits++;
            }
        }
        println("FindFloatWrite74: " + hits + " hits for disp " + disp);
    }
}
