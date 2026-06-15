// Headless GhidraScript: find functions whose instructions reference ALL of a
// set of scalar constants (e.g. struct displacements). Used to locate Match-class
// methods that touch both result-struct pointers this+0x400 and this+0x404 — the
// match-simulation routine writes those, the display fn 0x46a110 reads them
// (positive control). Args: <scalar1> [<scalar2> ...]  (hex, e.g. 0x400 0x404)
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import ghidra.app.script.GhidraScript;
import ghidra.program.model.lang.Register;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.scalar.Scalar;

public class FindFieldUsers extends GhidraScript {

    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        if (args.length < 1) {
            println("FindFieldUsers: need <scalar> [<scalar> ...]");
            return;
        }
        List<Long> wanted = new ArrayList<>();
        for (String a : args) {
            wanted.add(Long.parseLong(a.replace("0x", ""), 16));
        }

        var fm = currentProgram.getFunctionManager();
        for (Function f : fm.getFunctions(true)) {
            Set<Long> seen = new HashSet<>();
            Instruction ins = getInstructionAt(f.getEntryPoint());
            var body = f.getBody();
            while (ins != null && body.contains(ins.getAddress())) {
                int nOps = ins.getNumOperands();
                for (int oi = 0; oi < nOps; oi++) {
                    for (Object o : ins.getOpObjects(oi)) {
                        if (o instanceof Scalar s) {
                            long v = s.getUnsignedValue();
                            if (wanted.contains(v)) {
                                seen.add(v);
                            }
                        }
                    }
                    // displacement is not always an Op object; check the value too
                    Object[] objs = ins.getOpObjects(oi);
                    if (objs.length == 0) {
                        Scalar s = ins.getScalar(oi);
                        if (s != null && wanted.contains(s.getUnsignedValue())) {
                            seen.add(s.getUnsignedValue());
                        }
                    }
                }
                ins = ins.getNext();
            }
            if (seen.size() == wanted.size()) {
                long sz = f.getBody().getNumAddresses();
                println("MATCH " + f.getEntryPoint() + "  " + f.getName() + "  size=" + sz);
            }
        }
        println("FindFieldUsers: done");
    }
}
