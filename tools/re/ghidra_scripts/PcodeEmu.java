// Headless GhidraScript: PCode-emulate a decoded MANAGER.EXE function as a
// validation ORACLE for the EXACT match-engine port (docs/re/EXACT_PORT_PLAN.md).
//
// Reads a line-based spec file, sets up registers + memory + a synthetic stack,
// CALLs a function (cdecl/thiscall) one or more times, and captures EAX, chosen
// memory, and a step-level trace of chosen addresses (e.g. the RNG fn, to count
// + order the draws). No JSON dependency. Little-endian x86-32 (PE32).
//
// Usage: analyzeHeadless <proj-dir> <proj> -process MANAGER.EXE -noanalysis \
//          -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java <spec> <out>
//
// Spec grammar (one directive per line; '#' comments; hex may omit 0x):
//   entry   <va>                  function entry VA                       (required)
//   stack   <base> <size> <sp>    synthetic stack region + initial SP     (required)
//   ret     <va>                  return sentinel (breakpoint, never run) (required)
//   maxsteps <dec>               step budget per call (default 5000000)
//   reg     <NAME> <val>          preset a register before the FIRST call (repeatable)
//   zero    <base> <size>         zero-fill a region (back struct memory)  (repeatable)
//   mem     <addr> <size> <val>   write LE value before the FIRST call    (repeatable)
//   membts  <addr> <hexbytes>     write raw bytes before the FIRST call   (repeatable)
//   arg     <val>                 cdecl stack arg, pushed arg0,arg1,...   (repeatable)
//   calls   <dec>                 sequential invocations (default 1; globals persist)
//   read_reg <NAME>               capture this reg after each call        (repeatable)
//   read_mem <addr> <size>        capture LE memory value after each call (repeatable)
//   trace   <va>                  record step#+regs each time PC hits va  (repeatable)
//   trace_reg <NAME>              reg to snapshot at trace hits (default EAX) (repeatable)
//   stub    <va> <retval> <argbytes> [label]  on PC==va: set EAX=retval, pop ret + argbytes,
//                                 i.e. emulate a cdecl/stdcall callee returning retval
//                                 without executing it (for imports/uninteresting calls).
//                                 Each hit is logged "CALL c STUB label #n step=s ECX=.. arg0=.."
//                                 (arg0 = [esp+4], the first pushed arg) so stubbed-callee
//                                 SELECTION + ORDER + ARG stay observable; summary adds stubhits={}.
import java.io.File;
import java.io.PrintWriter;
import java.math.BigInteger;
import java.nio.file.Files;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import ghidra.app.emulator.EmulatorHelper;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.lang.Register;

public class PcodeEmu extends GhidraScript {

    private long hexVal(String s) {
        s = s.trim();
        boolean neg = s.startsWith("-");
        if (neg) s = s.substring(1).trim();
        if (s.startsWith("0x") || s.startsWith("0X")) s = s.substring(2);
        long v = new BigInteger(s, 16).longValue();
        return neg ? -v : v;
    }

    private long decVal(String s) { return Long.parseLong(s.trim()); }

    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        if (args.length < 2) { println("PcodeEmu: need <specFile> <outFile>"); return; }
        File specFile = new File(args[0]);
        File outFile = new File(args[1]);

        long entry = -1, retSentinel = -1, stackBase = -1, stackSize = -1, sp0 = -1;
        long maxsteps = 5_000_000L;
        long calls = 1;
        Map<String, Long> regPresets = new LinkedHashMap<>();
        List<long[]> zeroRegions = new ArrayList<>();    // {base,size}
        List<long[]> memWrites = new ArrayList<>();     // {addr,size,val}
        List<Object[]> byteWrites = new ArrayList<>();   // {addr(Long), bytes(byte[])}
        List<Long> stackArgs = new ArrayList<>();
        List<String> readRegs = new ArrayList<>();
        List<long[]> readMems = new ArrayList<>();        // {addr,size}
        Map<Long, String> traceAddrs = new LinkedHashMap<>();
        List<String> traceRegs = new ArrayList<>();
        Map<Long, long[]> stubs = new HashMap<>();        // va -> {retval, argbytes}
        Map<Long, String> stubLabels = new HashMap<>();   // va -> display label

        for (String raw : Files.readAllLines(specFile.toPath())) {
            String line = raw.trim();
            int hash = line.indexOf('#');
            if (hash >= 0) line = line.substring(0, hash).trim();
            if (line.isEmpty()) continue;
            String[] t = line.split("\\s+");
            switch (t[0]) {
                case "entry":     entry = hexVal(t[1]); break;
                case "ret":       retSentinel = hexVal(t[1]); break;
                case "maxsteps":  maxsteps = decVal(t[1]); break;
                case "calls":     calls = decVal(t[1]); break;
                case "stack":     stackBase = hexVal(t[1]); stackSize = hexVal(t[2]); sp0 = hexVal(t[3]); break;
                case "zero":      zeroRegions.add(new long[]{hexVal(t[1]), hexVal(t[2])}); break;
                case "reg":       regPresets.put(t[1], hexVal(t[2])); break;
                case "mem":       memWrites.add(new long[]{hexVal(t[1]), decVal(t[2]), hexVal(t[3])}); break;
                case "membts": {
                    long a = hexVal(t[1]);
                    byte[] b = new byte[t[2].replace("0x","").length()/2];
                    String h = t[2].replace("0x","");
                    for (int i=0;i<b.length;i++) b[i]=(byte)Integer.parseInt(h.substring(2*i,2*i+2),16);
                    byteWrites.add(new Object[]{a, b}); break;
                }
                case "arg":       stackArgs.add(hexVal(t[1])); break;
                case "read_reg":  readRegs.add(t[1]); break;
                case "read_mem":  readMems.add(new long[]{hexVal(t[1]), decVal(t[2])}); break;
                case "trace":     traceAddrs.put(hexVal(t[1]), t.length>2?t[2]:("t"+t[1])); break;
                case "trace_reg": traceRegs.add(t[1]); break;
                case "stub":
                    stubs.put(hexVal(t[1]), new long[]{hexVal(t[2]), decVal(t[3])});
                    stubLabels.put(hexVal(t[1]), t.length > 4 ? t[4] : ("0x" + Long.toHexString(hexVal(t[1]))));
                    break;
                default: println("PcodeEmu: WARN unknown directive: " + t[0]);
            }
        }
        if (entry < 0 || retSentinel < 0 || stackBase < 0) {
            println("PcodeEmu: spec missing entry/ret/stack"); return;
        }
        if (traceRegs.isEmpty()) traceRegs.add("EAX");
        if (readRegs.isEmpty()) readRegs.add("EAX");

        EmulatorHelper emu = new EmulatorHelper(currentProgram);
        Register pc = emu.getPCRegister();
        Register sp = emu.getStackPointerRegister();
        List<String> out = new ArrayList<>();
        out.add("# PcodeEmu result for spec " + specFile.getName());
        out.add("# entry=" + hex(entry) + " calls=" + calls);

        try {
            // Zero-init the synthetic stack region so reads/writes never fault.
            emu.writeMemory(toAddr(stackBase), new byte[(int) stackSize]);
            // Zero-back any struct regions the function reads but the spec doesn't set.
            for (long[] z : zeroRegions) emu.writeMemory(toAddr(z[0]), new byte[(int) z[1]]);

            // One-time globals + register presets (before the first call).
            for (long[] m : memWrites) writeLE(emu, m[0], (int) m[1], m[2]);
            for (Object[] b : byteWrites) emu.writeMemory(toAddr((Long) b[0]), (byte[]) b[1]);
            for (Map.Entry<String, Long> e : regPresets.entrySet())
                emu.writeRegister(e.getKey(), BigInteger.valueOf(e.getValue()));

            for (long call = 0; call < calls; call++) {
                int nargs = stackArgs.size();
                long espTop = sp0 - 4L * (1 + nargs);
                emu.writeRegister(sp, BigInteger.valueOf(espTop));
                writeLE(emu, espTop, 4, retSentinel);              // return address
                for (int i = 0; i < nargs; i++) writeLE(emu, espTop + 4L + 4L * i, 4, stackArgs.get(i));
                emu.writeRegister(pc, BigInteger.valueOf(entry));

                long steps = 0; String err = null; boolean returned = false;
                Map<String, Integer> traceCount = new LinkedHashMap<>();
                Map<String, Integer> stubCount = new LinkedHashMap<>();
                while (steps < maxsteps) {
                    Address cur = emu.getExecutionAddress();
                    long off = cur.getOffset();
                    if (off == retSentinel) { returned = true; break; }
                    if (stubs.containsKey(off)) {
                        // Emulate a callee returning retval: EAX=retval, pop ret addr (+ stdcall args).
                        long[] sdef = stubs.get(off);
                        long curSp = emu.readRegister(sp).longValue();
                        long retAddr = readLE(emu, curSp, 4);
                        long arg0 = readLE(emu, curSp + 4, 4);     // first pushed arg ([esp+4])
                        String lab = stubLabels.get(off);
                        int sn = stubCount.merge(lab, 1, Integer::sum);
                        out.add("CALL " + call + " STUB " + lab + " #" + sn + " step=" + steps
                                + " ECX=" + rd(emu, "ECX") + " arg0=" + arg0);
                        emu.writeRegister("EAX", BigInteger.valueOf(sdef[0]));
                        emu.writeRegister(sp, BigInteger.valueOf(curSp + 4 + sdef[1]));
                        emu.writeRegister(pc, BigInteger.valueOf(retAddr));
                        steps++;
                        continue;
                    }
                    if (traceAddrs.containsKey(off)) {
                        int n = traceCount.merge(traceAddrs.get(off), 1, Integer::sum);
                        StringBuilder sb = new StringBuilder();
                        sb.append("CALL ").append(call).append(" TRACE ").append(traceAddrs.get(off))
                          .append(" #").append(n).append(" step=").append(steps);
                        for (String r : traceRegs) sb.append(" ").append(r).append("=").append(rd(emu, r));
                        out.add(sb.toString());
                    }
                    boolean ok = emu.step(monitor);
                    if (!ok) { err = emu.getLastError(); break; }
                    steps++;
                }

                StringBuilder sb = new StringBuilder();
                sb.append("CALL ").append(call).append(returned ? " RET" : " HALT")
                  .append(" steps=").append(steps);
                if (err != null) sb.append(" err=\"").append(err).append("\" pc=").append(emu.getExecutionAddress());
                for (String r : readRegs) sb.append(" ").append(r).append("=").append(rd(emu, r));
                for (long[] m : readMems) sb.append(" mem[").append(hex(m[0])).append(":").append(m[1])
                                            .append("]=").append(readLE(emu, m[0], (int) m[1]));
                if (!traceCount.isEmpty()) sb.append(" tracehits=").append(traceCount);
                if (!stubCount.isEmpty()) sb.append(" stubhits=").append(stubCount);
                out.add(sb.toString());
            }
        } finally {
            emu.dispose();
        }

        try (PrintWriter pw = new PrintWriter(outFile)) { for (String l : out) pw.println(l); }
        println("PcodeEmu: wrote " + out.size() + " lines to " + outFile.getAbsolutePath());
    }

    private void writeLE(EmulatorHelper emu, long addr, int size, long val) {
        byte[] b = new byte[size];
        for (int i = 0; i < size; i++) b[i] = (byte) ((val >> (8 * i)) & 0xFF);
        emu.writeMemory(toAddr(addr), b);
    }

    private long readLE(EmulatorHelper emu, long addr, int size) {
        byte[] b = emu.readMemory(toAddr(addr), size);
        long v = 0;
        for (int i = 0; i < size; i++) v |= (b[i] & 0xFFL) << (8 * i);
        return v;
    }

    private long rd(EmulatorHelper emu, String reg) { return emu.readRegister(reg).longValue(); }

    private String hex(long v) { return "0x" + Long.toHexString(v); }
}
