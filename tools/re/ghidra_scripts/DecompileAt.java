// Headless GhidraScript: decompile the function CONTAINING each given VA. If
// auto-analysis left the region undefined (common for vtable-only-reached code),
// disassemble at the VA and create a function there first. Also dumps direct
// callees (one level) so format strings / helpers give constant context.
// Args: <outDir> <VA> [<VA> ...]   VAs hex (with or without 0x).
import java.io.File;
import java.io.PrintWriter;
import java.util.LinkedHashSet;
import java.util.Set;

import ghidra.app.cmd.disassemble.DisassembleCommand;
import ghidra.app.cmd.function.CreateFunctionCmd;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressSet;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionManager;

public class DecompileAt extends GhidraScript {

    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        if (args.length < 2) {
            println("DecompileAt: need <outDir> <VA> [...]");
            return;
        }
        File outDir = new File(args[0]);
        outDir.mkdirs();
        FunctionManager fm = currentProgram.getFunctionManager();

        Set<Function> toDump = new LinkedHashSet<>();
        for (int i = 1; i < args.length; i++) {
            long v = Long.parseLong(args[i].replace("0x", ""), 16);
            Address a = toAddr(v);
            Function f = fm.getFunctionContaining(a);
            if (f == null) {
                // Disassemble then create a function at this address.
                DisassembleCommand dis = new DisassembleCommand(a, null, true);
                dis.applyTo(currentProgram, monitor);
                CreateFunctionCmd cf = new CreateFunctionCmd(a);
                cf.applyTo(currentProgram, monitor);
                f = fm.getFunctionContaining(a);
            }
            if (f == null) {
                println("WARN still no function at " + a);
                continue;
            }
            toDump.add(f);
            for (Function c : f.getCalledFunctions(monitor)) {
                toDump.add(c);
            }
        }

        DecompInterface dec = new DecompInterface();
        dec.openProgram(currentProgram);
        int ok = 0;
        for (Function f : toDump) {
            DecompileResults res = dec.decompileFunction(f, 90, monitor);
            String body = (res != null && res.decompileCompleted())
                    ? res.getDecompiledFunction().getC()
                    : "// DECOMPILE FAILED: " + (res == null ? "null" : res.getErrorMessage());
            if (res != null && res.decompileCompleted()) ok++;
            String fname = "fn_" + f.getEntryPoint() + "_" + f.getName().replaceAll("[^A-Za-z0-9_]", "_") + ".c";
            try (PrintWriter pw = new PrintWriter(new File(outDir, fname))) {
                pw.println("// " + f.getName() + "  entry=" + f.getEntryPoint()
                        + "  size=" + f.getBody().getNumAddresses() + " bytes");
                pw.println(body);
            }
        }
        println("DecompileAt: dumped " + toDump.size() + " functions (" + ok + " ok) to " + outDir.getAbsolutePath());
    }
}
