// Headless GhidraScript: walk the DIRECT-call closure from each seed VA using
// Ghidra's real function boundaries and report every closure member that calls
// the RNG draw FUN_005ec250, plus the call chain that reaches it. Optional
// exclude list lets us model gated-off branches (e.g. the highlight replayer).
// Args: <seedVA> [<seedVA> ...] [-x <excludeVA,excludeVA,...>]
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.symbol.FlowType;
import ghidra.program.model.symbol.Reference;

public class ScanRngReach extends GhidraScript {
    static final long RNG = 0x5ec250L;

    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        List<Long> seeds = new ArrayList<>();
        Set<Long> exclude = new HashSet<>();
        for (int i = 0; i < args.length; i++) {
            if (args[i].equals("-x")) {
                for (String s : args[++i].split(","))
                    exclude.add(Long.parseLong(s.replace("0x", ""), 16));
            } else {
                seeds.add(Long.parseLong(args[i].replace("0x", ""), 16));
            }
        }
        FunctionManager fm = currentProgram.getFunctionManager();
        for (long seed : seeds) {
            Map<Long, Long> parent = new HashMap<>();
            Set<Long> seen = new HashSet<>();
            ArrayDeque<Long> frontier = new ArrayDeque<>();
            frontier.add(seed);
            seen.add(seed);
            List<Long> rngCallers = new ArrayList<>();
            while (!frontier.isEmpty()) {
                long va = frontier.poll();
                Address a = toAddr(va);
                Function f = fm.getFunctionAt(a);
                if (f == null) {
                    Instruction ins = getInstructionAt(a);
                    if (ins == null) continue;
                    f = fm.getFunctionContaining(a);
                    if (f == null) continue;
                }
                for (Instruction ins : currentProgram.getListing()
                        .getInstructions(f.getBody(), true)) {
                    if (!ins.getFlowType().isCall()) continue;
                    for (Reference r : ins.getReferencesFrom()) {
                        FlowType ft = r.getReferenceType().isCall()
                                ? null : null;
                        long tgt = r.getToAddress().getOffset();
                        if (!r.getReferenceType().isCall()) continue;
                        if (tgt == RNG && !rngCallers.contains(va)) rngCallers.add(va);
                        if (tgt >= 0x400000L && tgt < 0x630000L && tgt != RNG
                                && !exclude.contains(tgt) && seen.add(tgt)) {
                            parent.put(tgt, va);
                            frontier.add(tgt);
                        }
                    }
                }
            }
            StringBuilder sb = new StringBuilder();
            sb.append(String.format("seed 0x%x: closure=%d rngCallers=%d%n",
                    seed, seen.size(), rngCallers.size()));
            for (long rc : rngCallers) {
                sb.append("  RNG caller 0x").append(Long.toHexString(rc)).append(" chain: ");
                long cur = rc;
                List<String> chain = new ArrayList<>();
                while (parent.containsKey(cur)) {
                    chain.add("0x" + Long.toHexString(cur));
                    cur = parent.get(cur);
                }
                chain.add("0x" + Long.toHexString(cur));
                sb.append(String.join(" <- ", chain)).append("\n");
            }
            println(sb.toString());
        }
    }
}
