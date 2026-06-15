// Headless GhidraScript: decompile a set of seed functions plus their direct
// callers and callees, writing one .c file per function (named by entry VA) and
// a callgraph.txt edge list. Args: <outDir> <seedVA> [<seedVA> ...]
// VAs are hex (with or without 0x). Used to walk from the PM98 "MATCH RESULT"
// reporting fn (0x46a338) outward to the match-simulation routine.
import java.io.File;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.symbol.ReferenceManager;

public class ExportFns extends GhidraScript {

    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        if (args.length < 2) {
            println("ExportFns: need <outDir> <seedVA> [...]");
            return;
        }
        File outDir = new File(args[0]);
        outDir.mkdirs();

        FunctionManager fm = currentProgram.getFunctionManager();
        ReferenceManager rm = currentProgram.getReferenceManager();

        // Resolve seed functions.
        Set<Function> seeds = new LinkedHashSet<>();
        for (int i = 1; i < args.length; i++) {
            long v = Long.parseLong(args[i].replace("0x", ""), 16);
            Address a = toAddr(v);
            Function f = fm.getFunctionContaining(a);
            if (f == null) {
                println("WARN no function contains " + a);
                continue;
            }
            seeds.add(f);
        }

        // Expand to seeds + direct callers + direct callees.
        Set<Function> toDump = new LinkedHashSet<>(seeds);
        List<String> edges = new ArrayList<>();
        for (Function f : seeds) {
            for (Function c : f.getCallingFunctions(monitor)) {
                toDump.add(c);
                edges.add(hx(c) + " -> " + hx(f) + "  [caller of seed " + nm(f) + "]");
            }
            for (Function c : f.getCalledFunctions(monitor)) {
                toDump.add(c);
                edges.add(hx(f) + " -> " + hx(c) + "  [callee of seed " + nm(f) + "]");
            }
        }

        DecompInterface dec = new DecompInterface();
        dec.openProgram(currentProgram);

        int ok = 0;
        for (Function f : toDump) {
            DecompileResults res = dec.decompileFunction(f, 60, monitor);
            String body;
            if (res != null && res.decompileCompleted()) {
                body = res.getDecompiledFunction().getC();
                ok++;
            } else {
                body = "// DECOMPILE FAILED: " + (res == null ? "null" : res.getErrorMessage());
            }
            String fname = "fn_" + hx(f) + "_" + safe(f.getName()) + ".c";
            try (PrintWriter pw = new PrintWriter(new File(outDir, fname))) {
                pw.println("// " + nm(f) + "  entry=" + hx(f)
                        + "  size=" + f.getBody().getNumAddresses() + " bytes");
                pw.println("// callers/callees expanded one level from seeds");
                pw.println(body);
            }
        }

        // Callgraph + caller/callee inventory for the seeds (for the next walk step).
        try (PrintWriter pw = new PrintWriter(new File(outDir, "callgraph.txt"))) {
            for (String e : edges) {
                pw.println(e);
            }
        }
        println("ExportFns: dumped " + toDump.size() + " functions (" + ok
                + " decompiled) to " + outDir.getAbsolutePath());
    }

    private String nm(Function f) {
        return f.getName();
    }

    private String hx(Function f) {
        return f.getEntryPoint().toString();
    }

    private String safe(String s) {
        return s.replaceAll("[^A-Za-z0-9_]", "_");
    }
}
