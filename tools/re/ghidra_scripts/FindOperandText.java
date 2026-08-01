// Headless GhidraScript: print every instruction whose text contains ALL of the given
// substrings, with its containing function. The blunt instrument the other scanners are
// specialisations of -- FindStoreDisp only matches a write displacement, FindRefsTo only
// matches a resolved reference, and neither can answer "which code touches the widget
// array at this class offset" when the base is a register the analyser never typed.
// Args: <needle> [<needle> ...]   e.g. 0xadc0
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;

public class FindOperandText extends GhidraScript {
    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        if (args.length == 0) {
            println("usage: FindOperandText <needle> [<needle> ...]");
            return;
        }
        int n = 0;
        for (Instruction ins : currentProgram.getListing().getInstructions(true)) {
            String t = ins.toString().toLowerCase();
            boolean all = true;
            for (String a : args) {
                if (!t.contains(a.toLowerCase())) { all = false; break; }
            }
            if (!all) continue;
            Function fn = getFunctionContaining(ins.getAddress());
            println("HIT " + ins.getAddress() + " " + ins.toString()
                    + "   in " + (fn == null ? "<none>" : fn.getName() + "@" + fn.getEntryPoint()));
            n++;
        }
        println("FindOperandText: " + n + " hits");
    }
}
