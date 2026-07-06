// Headless GhidraScript: find functions that perform a DWORD-sized store to a
// memory operand at a given displacement (e.g. `MOV dword ptr [reg+0x1928], src`)
// and print the exact instruction + address. Companion to FindWordStore.java.
// Args: <dispHex> [<dispHex2> ...]
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;

public class FindDwordStore extends GhidraScript {

    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        if (args.length < 1) {
            println("FindDwordStore: need <dispHex> [...]");
            return;
        }
        List<Pattern> pats = new ArrayList<>();
        for (String a : args) {
            String d = a.toLowerCase().startsWith("0x") ? a.substring(2) : a;
            pats.add(Pattern.compile("dword ptr \\[[^\\]]*0x" + d + "\\] *,", Pattern.CASE_INSENSITIVE));
        }
        var fm = currentProgram.getFunctionManager();
        int n = 0;
        for (Function f : fm.getFunctions(true)) {
            Instruction ins = getInstructionAt(f.getEntryPoint());
            var body = f.getBody();
            while (ins != null && body.contains(ins.getAddress())) {
                String s = ins.toString();
                if (s.startsWith("MOV") || s.startsWith("mov")) {
                    for (Pattern p : pats) {
                        if (p.matcher(s).find()) {
                            println("STORE " + ins.getAddress() + "  " + s + "   in " + f.getName() + "@"
                                    + f.getEntryPoint());
                            n++;
                        }
                    }
                }
                ins = ins.getNext();
            }
        }
        println("FindDwordStore: " + n + " stores");
    }
}
