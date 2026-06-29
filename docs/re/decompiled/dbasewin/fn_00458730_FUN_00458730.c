// FUN_00458730  entry=00458730  size=321 bytes

void __thiscall
FUN_00458730(void *this,undefined4 param_1,int param_2,undefined2 param_3,undefined2 param_4,
            int param_5)

{
  undefined1 *puVar1;
  int *piVar2;
  undefined4 *puVar3;
  int iVar4;
  int iVar5;
  
  if ((-1 < param_2) && (param_2 < 5)) {
    if (param_5 == -1) {
      param_5 = *(int *)((int)this + param_2 * 8 + 0x364);
    }
    if (param_5 < *(int *)((int)this + param_2 * 8 + 0x364)) {
      FUN_00458880(this,param_2,param_5);
    }
    else {
      piVar2 = (int *)((int)this + param_2 * 8 + 0x360);
      iVar5 = param_5 + 1;
      iVar4 = *(int *)((int)this + param_2 * 8 + 0x364);
      while (iVar5 < iVar4) {
        piVar2[1] = iVar4 + -1;
        iVar4 = *piVar2 + (iVar4 + -1) * 0x94;
        if (iVar4 != 0) {
          FUN_0045ad20(iVar4);
        }
        iVar4 = piVar2[1];
      }
      FUN_0044fb30(piVar2,iVar5 * 0x94);
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
    iVar4 = param_5 * 0x94;
    puVar3 = (undefined4 *)(iVar4 + 0x80 + *(int *)((int)this + param_2 * 8 + 0x360));
    *puVar3 = param_1;
    puVar3[1] = 1;
    *(undefined4 *)(iVar4 + 0x84 + *(int *)((int)this + param_2 * 8 + 0x360)) = 0;
    *(undefined2 *)(iVar4 + 0x90 + *(int *)((int)this + param_2 * 8 + 0x360)) = param_3;
    *(undefined2 *)(iVar4 + 0x92 + *(int *)((int)this + param_2 * 8 + 0x360)) = param_4;
  }
  return;
}


