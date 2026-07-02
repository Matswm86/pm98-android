// FUN_005b2f30  entry=005b2f30  size=301 bytes

void __fastcall FUN_005b2f30(int param_1)

{
  int iVar1;
  int iVar2;
  int *piVar3;
  undefined4 uVar4;
  
  if ((*(int *)(param_1 + 0x13c) != 1) && (*(int *)(param_1 + 0x17c) < 0x50000)) {
    *(undefined4 *)(param_1 + 0x144) = 0;
    iVar2 = FUN_005ec250();
    *(undefined4 *)(param_1 + 0x13c) = 1;
    *(int *)(param_1 + 0x148) =
         ((int)(iVar2 * 0x32 + (iVar2 * 0x32 >> 0x1f & 0x7fffU)) >> 0xf) + 0x32;
    *(int *)(param_1 + 0x158) = *(int *)(param_1 + 4);
    *(undefined4 *)(param_1 + 0x15c) = *(undefined4 *)(param_1 + 8);
    *(undefined4 *)(param_1 + 0x160) = *(undefined4 *)(param_1 + 0xc);
    iVar2 = FUN_005ec250();
    piVar3 = (int *)FUN_005ee0f0(0x140000,(int)(iVar2 * 0xff + (iVar2 * 0xff >> 0x1f & 0x7fU)) >> 7)
    ;
    iVar2 = piVar3[1];
    iVar1 = piVar3[2];
    *(int *)(param_1 + 0x164) = *(int *)(param_1 + 4) + *piVar3;
    *(int *)(param_1 + 0x168) = iVar2 + *(int *)(param_1 + 8);
    *(int *)(param_1 + 0x16c) = iVar1 + *(int *)(param_1 + 0xc);
  }
  if (*(int *)(param_1 + 0x144) < *(int *)(param_1 + 0x148)) {
    iVar2 = param_1 + 0x164;
    uVar4 = 0x5a;
  }
  else {
    iVar2 = param_1 + 0x158;
    uVar4 = 0x28;
  }
  FUN_005a89c0(iVar2,uVar4);
  if (0x50000 < *(int *)(param_1 + 0x17c)) {
    *(undefined4 *)(param_1 + 0x13c) = 0;
  }
  iVar2 = *(int *)(param_1 + 0x144);
  *(int *)(param_1 + 0x144) = iVar2 + 1;
  if (iVar2 == *(int *)(param_1 + 0x148) * 2) {
    *(undefined4 *)(param_1 + 0x13c) = 0;
  }
  return;
}


