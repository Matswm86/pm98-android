// FUN_005c0d50  entry=005c0d50  size=321 bytes
// callers/callees expanded one level from seeds

void __thiscall
FUN_005c0d50(int param_1,undefined4 param_2,int param_3,undefined2 param_4,undefined2 param_5,
            int param_6)

{
  undefined1 *puVar1;
  int *piVar2;
  undefined4 *puVar3;
  int iVar4;
  int iVar5;
  
  if ((-1 < param_3) && (param_3 < 5)) {
    if (param_6 == -1) {
      param_6 = *(int *)(param_1 + 0x364 + param_3 * 8);
    }
    if (param_6 < *(int *)(param_1 + 0x364 + param_3 * 8)) {
      FUN_005c0ea0(param_3,param_6);
    }
    else {
      piVar2 = (int *)(param_1 + 0x360 + param_3 * 8);
      iVar5 = param_6 + 1;
      iVar4 = *(int *)(param_1 + 0x364 + param_3 * 8);
      while (iVar5 < iVar4) {
        piVar2[1] = iVar4 + -1;
        if (*piVar2 + (iVar4 + -1) * 0x94 != 0) {
          FUN_005c3320(1);
        }
        iVar4 = piVar2[1];
      }
      FUN_005bbf10(piVar2,iVar5 * 0x94);
      iVar4 = piVar2[1];
      piVar2[1] = iVar4;
      while (iVar4 < iVar5) {
        puVar1 = (undefined1 *)(*piVar2 + piVar2[1] * 0x94);
        if (puVar1 != (undefined1 *)0x0) {
          *puVar1 = 0;
          *(undefined4 *)(puVar1 + 0x80) = 0;
          *(undefined4 *)(puVar1 + 0x84) = 1;
          *(undefined4 *)(puVar1 + 0x88) = 0;
          *(undefined4 *)(puVar1 + 0x8c) = 1;
        }
        iVar4 = piVar2[1] + 1;
        piVar2[1] = iVar4;
      }
    }
    param_6 = param_6 * 0x94;
    puVar3 = (undefined4 *)(param_6 + 0x80 + *(int *)(param_1 + 0x360 + param_3 * 8));
    *puVar3 = param_2;
    puVar3[1] = 1;
    *(undefined4 *)(param_6 + 0x84 + *(int *)(param_1 + 0x360 + param_3 * 8)) = 0;
    *(undefined2 *)(param_6 + 0x90 + *(int *)(param_1 + 0x360 + param_3 * 8)) = param_4;
    *(undefined2 *)(param_6 + 0x92 + *(int *)(param_1 + 0x360 + param_3 * 8)) = param_5;
  }
  return;
}


