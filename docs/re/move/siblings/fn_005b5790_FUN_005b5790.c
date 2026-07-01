// FUN_005b5790  entry=005b5790  size=392 bytes

void __fastcall FUN_005b5790(int param_1)

{
  int iVar1;
  int iVar2;
  undefined4 *puVar3;
  undefined4 *puVar4;
  
  FUN_005ed870();
  iVar2 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1a5c);
  *(undefined4 *)(param_1 + 0x3bc) = 0;
  *(int *)(param_1 + 0x2dc) = iVar2 + 0x400;
  *(undefined4 *)(param_1 + 0x3c0) = 0;
  *(undefined4 *)(param_1 + 0x3c4) = 0;
  *(undefined4 *)(param_1 + 0x3c8) = 0;
  *(undefined4 *)(param_1 + 0x3cc) = 0;
  *(undefined1 *)(param_1 + 0x3d0) = 0;
  if (DAT_006d31c4 == '\0') {
    FUN_005bbf10(param_1 + 0x3b0,0);
    *(undefined4 *)(param_1 + 0x3b4) = 0;
    *(undefined4 *)(param_1 + 4) = 0;
    *(undefined4 *)(param_1 + 8) = 0;
    *(undefined4 *)(param_1 + 0xc) = 0;
    FUN_005a5430(0x38);
    switch(*(undefined4 *)(*(int *)(param_1 + 0x18c) + 0x448)) {
    case 2:
    case 6:
      *(undefined4 *)(param_1 + 4) = 0x40000;
      *(undefined4 *)(param_1 + 8) = 0x80000;
      return;
    case 4:
      iVar2 = MulDiv(*(int *)(*(int *)(param_1 + 400) + 0x90),0x50,100);
      *(int *)(param_1 + 4) = iVar2;
      iVar2 = MulDiv(-*(int *)(*(int *)(param_1 + 400) + 0x94),0x32,100);
      *(int *)(param_1 + 8) = iVar2;
      return;
    case 5:
      if (*(int *)(*(int *)(param_1 + 0x18c) + 0x19cc) != 0) {
        iVar2 = *(int *)(param_1 + 400);
        *(undefined4 *)(param_1 + 4) = *(undefined4 *)(iVar2 + 0x90);
        *(undefined4 *)(param_1 + 8) = *(undefined4 *)(iVar2 + 0x94);
        *(undefined4 *)(param_1 + 0xc) = *(undefined4 *)(iVar2 + 0x98);
        iVar2 = *(int *)(param_1 + 8);
        iVar1 = -iVar2;
        *(int *)(param_1 + 8) = iVar1;
        if (iVar1 < 0) {
          if (iVar2 != 0xf0000 && -0xf0001 < iVar1) {
            *(undefined4 *)(param_1 + 8) = 0xfff10000;
            return;
          }
        }
        else if (iVar1 < 0xf0000) {
          *(undefined4 *)(param_1 + 8) = 0xf0000;
          return;
        }
      }
      break;
    case 7:
      iVar2 = *(int *)(param_1 + 400);
      *(undefined4 *)(param_1 + 4) = *(undefined4 *)(iVar2 + 0x90);
      *(undefined4 *)(param_1 + 8) = *(undefined4 *)(iVar2 + 0x94);
      *(undefined4 *)(param_1 + 0xc) = *(undefined4 *)(iVar2 + 0x98);
      *(int *)(param_1 + 8) = *(int *)(param_1 + 8) + 0xc0000;
    }
    return;
  }
  if (param_1 != 0) {
    puVar3 = *(undefined4 **)(param_1 + 0x3b0);
    puVar4 = (undefined4 *)(param_1 + 0x40);
    for (iVar2 = 0x51; iVar2 != 0; iVar2 = iVar2 + -1) {
      *puVar4 = *puVar3;
      puVar3 = puVar3 + 1;
      puVar4 = puVar4 + 1;
    }
    return;
  }
  puVar3 = puRam000003b0;
  puVar4 = (undefined4 *)0x0;
  for (iVar2 = 0x51; iVar2 != 0; iVar2 = iVar2 + -1) {
    *puVar4 = *puVar3;
    puVar3 = puVar3 + 1;
    puVar4 = puVar4 + 1;
  }
  return;
}


