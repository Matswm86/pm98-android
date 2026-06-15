// Headless GhidraScript: find functions that perform a WORD-sized store to a
// memory operand at a given displacement (e.g. [reg+0x38]) — i.e. `result->goals
// = computed`. The match-result display fns only READ +0x38/+0x3a; the SIM writes
// them. Args: <dispHex> [<dispHex2> ...]  e.g. 0x38 0x3a
// Reports each function with a write to ANY listed disp, flagging which disps and
// whether the store source is an immediate or a register (a computed value).
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeSet;
import java.util.regex.Pattern;

import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;

public class FindWordStore extends GhidraScript {

    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        if (args.length < 1) {
            println("FindWordStore: need <dispHex> [...]  e.g. 0x38 0x3a");
            return;
        }
        // Build a regex per disp: word ptr [ ... 0x38 ] ,   (destination = memory write)
        List<String> disps = new ArrayList<>();
        List<Pattern> pats = new ArrayList<>();
        for (String a : args) {
            String d = a.toLowerCase().startsWith("0x") ? a.substring(2) : a;
            disps.add("0x" + d);
            pats.add(Pattern.compile("word ptr \\[[^\\]]*0x" + d + "\\] *,", Pattern.CASE_INSENSITIVE));
        }

        var fm = currentProgram.getFunctionManager();
        Map<String, String> hits = new LinkedHashMap<>();
        for (Function f : fm.getFunctions(true)) {
            TreeSet<String> got = new TreeSet<>();
            boolean immOnly = true;
            Instruction ins = getInstructionAt(f.getEntryPoint());
            var body = f.getBody();
            while (ins != null && body.contains(ins.getAddress())) {
                String s = ins.toString();
                String m = ins.getMnemonicString();
                if (m.startsWith("MOV") || m.startsWith("mov")) {
                    for (int i = 0; i < disps.size(); i++) {
                        if (pats.get(i).matcher(s).find()) {
                            got.add(disps.get(i));
                            // source operand 1: register => computed; const => literal
                            if (ins.getNumOperands() >= 2 && ins.getRegister(1) != null) {
                                immOnly = false;
                            }
                        }
                    }
                }
                ins = ins.getNext();
            }
            if (!got.isEmpty()) {
                hits.put(f.getEntryPoint().toString(),
                        f.getName() + "  disps=" + got + (immOnly ? "  (imm src)" : "  (REG src=computed)")
                                + "  size=" + f.getBody().getNumAddresses());
            }
        }
        println("=== functions with word-store to " + disps + " ===");
        for (var e : hits.entrySet()) {
            println("  " + e.getKey() + "  " + e.getValue());
        }
        println("FindWordStore: " + hits.size() + " functions");
    }
}
