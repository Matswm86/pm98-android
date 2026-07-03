// Headless GhidraScript: batch PCode-emulation sweep — many independent calls of
// one function in a single headless run, each with its OWN stack args and per-call
// memory writes. Built to dump exhaustive truth tables from pure decision functions
// (first use: FUN_004179a0, the post-match morale delta matrix — 600 combos).
// PcodeEmu.java runs ONE arg-set N times; this runs N arg-sets once each.
//
// Usage: analyzeHeadless <proj-dir> <proj> -process MANAGER.EXE -noanalysis \
//          -scriptPath tools/re/ghidra_scripts -postScript SweepEmu.java <spec> <out>
//
// Spec grammar ('#' comments; hex may omit 0x):
//   entry   <va>                 function entry VA                     (required)
//   stack   <base> <size> <sp>   synthetic stack region + initial SP   (required)
//   ret     <va>                 return sentinel (never executed)      (required)
//   maxsteps <dec>               step budget per call (default 100000)
//   zero    <base> <size>        zero-fill once, before all calls      (repeatable)
//   mem     <addr> <size> <val>  LE write once, before all calls       (repeatable)
//   call    <tag> | a1 a2 ... | <addr>:<size>:<val> <addr>:<size>:<val> ...
//                                one emulated call: label, cdecl stack args,
//                                per-call LE memory writes (both lists may be empty,
//                                pipes required). EAX is captured after each call.
// Output: one line per call:  <tag> RET|HALT eax=<signed int32> steps=<n>
import java.io.File;
import java.io.PrintWriter;
import java.math.BigInteger;
import java.nio.file.Files;
import java.util.ArrayList;
import java.util.List;

import ghidra.app.emulator.EmulatorHelper;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.lang.Register;

public class SweepEmu extends GhidraScript {

    private long hexVal(String s) {
        s = s.trim();
        boolean neg = s.startsWith("-");
        if (neg) s = s.substring(1).trim();
        if (s.startsWith("0x") || s.startsWith("0X")) s = s.substring(2);
        long v = new BigInteger(s, 16).longValue();
        return neg ? -v : v;
    }

    private static final class CallSpec {
        String tag;
        List<Long> args = new ArrayList<>();
        List<long[]> mems = new ArrayList<>();   // {addr,size,val}
    }

    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        if (args.length < 2) { println("SweepEmu: need <specFile> <outFile>"); return; }
        long entry = -1, retSentinel = -1, stackBase = -1, stackSize = -1, sp0 = -1;
        long maxsteps = 100_000L;
        List<long[]> zeroRegions = new ArrayList<>();
        List<long[]> memWrites = new ArrayList<>();
        List<CallSpec> callSpecs = new ArrayList<>();

        for (String raw : Files.readAllLines(new File(args[0]).toPath())) {
            String line = raw.trim();
            int hash = line.indexOf('#');
            if (hash >= 0) line = line.substring(0, hash).trim();
            if (line.isEmpty()) continue;
            String[] t = line.split("\\s+", 2);
            switch (t[0]) {
                case "entry":    entry = hexVal(t[1].split("\\s+")[0]); break;
                case "ret":      retSentinel = hexVal(t[1].split("\\s+")[0]); break;
                case "maxsteps": maxsteps = Long.parseLong(t[1].split("\\s+")[0]); break;
                case "stack": {
                    String[] s = t[1].split("\\s+");
                    stackBase = hexVal(s[0]); stackSize = hexVal(s[1]); sp0 = hexVal(s[2]);
                    break;
                }
                case "zero": {
                    String[] s = t[1].split("\\s+");
                    zeroRegions.add(new long[]{hexVal(s[0]), hexVal(s[1])});
                    break;
                }
                case "mem": {
                    String[] s = t[1].split("\\s+");
                    memWrites.add(new long[]{hexVal(s[0]), Long.parseLong(s[1]), hexVal(s[2])});
                    break;
                }
                case "call": {
                    String[] parts = t[1].split("\\|", -1);
                    if (parts.length != 3) { println("SweepEmu: bad call line: " + line); return; }
                    CallSpec c = new CallSpec();
                    c.tag = parts[0].trim();
                    for (String a : parts[1].trim().split("\\s+"))
                        if (!a.isEmpty()) c.args.add(hexVal(a));
                    for (String m : parts[2].trim().split("\\s+")) {
                        if (m.isEmpty()) continue;
                        String[] f = m.split(":");
                        c.mems.add(new long[]{hexVal(f[0]), Long.parseLong(f[1]), hexVal(f[2])});
                    }
                    callSpecs.add(c);
                    break;
                }
                default: println("SweepEmu: WARN unknown directive: " + t[0]);
            }
        }
        if (entry < 0 || retSentinel < 0 || stackBase < 0 || callSpecs.isEmpty()) {
            println("SweepEmu: spec missing entry/ret/stack/call"); return;
        }

        EmulatorHelper emu = new EmulatorHelper(currentProgram);
        Register pc = emu.getPCRegister();
        Register sp = emu.getStackPointerRegister();
        List<String> out = new ArrayList<>();
        out.add("# SweepEmu entry=0x" + Long.toHexString(entry) + " calls=" + callSpecs.size());
        try {
            emu.writeMemory(toAddr(stackBase), new byte[(int) stackSize]);
            for (long[] z : zeroRegions) emu.writeMemory(toAddr(z[0]), new byte[(int) z[1]]);
            for (long[] m : memWrites) writeLE(emu, m[0], (int) m[1], m[2]);

            for (CallSpec c : callSpecs) {
                for (long[] m : c.mems) writeLE(emu, m[0], (int) m[1], m[2]);
                int nargs = c.args.size();
                long espTop = sp0 - 4L * (1 + nargs);
                emu.writeRegister(sp, BigInteger.valueOf(espTop));
                writeLE(emu, espTop, 4, retSentinel);
                for (int i = 0; i < nargs; i++) writeLE(emu, espTop + 4L + 4L * i, 4, c.args.get(i));
                emu.writeRegister(pc, BigInteger.valueOf(entry));

                long steps = 0; boolean returned = false; String err = null;
                while (steps < maxsteps) {
                    if (emu.getExecutionAddress().getOffset() == retSentinel) { returned = true; break; }
                    if (!emu.step(monitor)) { err = emu.getLastError(); break; }
                    steps++;
                }
                int eax = (int) emu.readRegister("EAX").longValue();
                out.add(c.tag + (returned ? " RET" : " HALT") + " eax=" + eax + " steps=" + steps
                        + (err != null ? " err=\"" + err + "\"" : ""));
            }
        } finally {
            emu.dispose();
        }
        try (PrintWriter pw = new PrintWriter(new File(args[1]))) { for (String l : out) pw.println(l); }
        println("SweepEmu: wrote " + out.size() + " lines to " + args[1]);
    }

    private void writeLE(EmulatorHelper emu, long addr, int size, long val) {
        byte[] b = new byte[size];
        for (int i = 0; i < size; i++) b[i] = (byte) ((val >> (8 * i)) & 0xFF);
        emu.writeMemory(toAddr(addr), b);
    }
}
