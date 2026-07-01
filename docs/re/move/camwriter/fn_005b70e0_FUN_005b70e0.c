// FUN_005b70e0  entry=005b70e0  size=692 bytes

void __fastcall FUN_005b70e0(int *param_1)

{
  undefined2 uVar1;
  short sVar2;
  uint uVar3;
  int iVar4;
  undefined4 *puVar5;
  uint uVar6;
  int iVar7;
  int iVar8;
  int *piVar9;
  bool bVar10;
  int iStack_18;
  int local_14;
  undefined1 auStack_c [12];
  
  iVar8 = 0;
  iVar7 = 0x27100000;
  local_14 = param_1[1];
  piVar9 = (int *)*param_1;
  param_1[0xb7] = 0;
  param_1[0x80] = 0;
  param_1[0x7f] = 0;
  while (local_14 != 0) {
    local_14 = local_14 + -1;
    (**(code **)(*piVar9 + 4))();
    piVar9 = piVar9 + 0xef;
  }
  if (((DAT_006d31c4 == '\0') && (*(int *)(param_1[0x4e] + 0x448) == 2)) &&
     (*(int *)(param_1[0x4e] + 0x45c) == param_1[2])) {
    iStack_18 = *param_1;
    local_14 = param_1[1] + -1;
    if (param_1[1] != 0) {
      piVar9 = (int *)(iStack_18 + 8);
      do {
        if ((iStack_18 != *(int *)(piVar9[0x61] + 0x438)) && (piVar9[0xad] != 0)) {
          iVar4 = param_1[0x4e];
          uVar3 = piVar9[-1] - *(int *)(iVar4 + 0x16a0);
          uVar6 = (int)uVar3 >> 0x1f;
          if (((int)((uVar3 ^ uVar6) - uVar6) < iVar7) &&
             ((uVar3 = *piVar9 - *(int *)(iVar4 + 0x16a4), uVar6 = (int)uVar3 >> 0x1f,
              (int)((uVar3 ^ uVar6) - uVar6) < iVar7 &&
              (uVar3 = piVar9[1] - *(int *)(iVar4 + 0x16a8), uVar6 = (int)uVar3 >> 0x1f,
              (int)((uVar3 ^ uVar6) - uVar6) < iVar7)))) {
            bVar10 = true;
          }
          else {
            bVar10 = false;
          }
          if (bVar10) {
            FUN_00590aa0(*(int *)(iVar4 + 0x16a0) - piVar9[-1],*(int *)(iVar4 + 0x16a4) - *piVar9,
                         *(int *)(iVar4 + 0x16a8) - piVar9[1]);
            iVar4 = FUN_005b1260();
            if (iVar4 < iVar7) {
              iVar7 = iVar4;
              iVar8 = iStack_18;
            }
          }
        }
        iStack_18 = iStack_18 + 0x3bc;
        piVar9 = piVar9 + 0xef;
        iVar4 = local_14 + -1;
        bVar10 = local_14 != 0;
        local_14 = iVar4;
      } while (bVar10);
    }
    if (iVar8 != 0) {
      *(undefined1 *)(iVar8 + 99) = 1;
      *(int *)(iVar8 + 4) =
           (-(uint)(*(uint *)(iVar8 + 0x2b8) != (*(uint *)(*(int *)(iVar8 + 0x18c) + 0x19a0) & 1)) &
           0xcccc) - 0x6666;
      *(uint *)(iVar8 + 8) = ((*(int *)(iVar8 + 8) < 0) - 1 & 0x30000) - 0x18000;
      puVar5 = (undefined4 *)FUN_00590ae0(auStack_c,(int *)(iVar8 + 4));
      uVar1 = FUN_005ee080(*puVar5,puVar5[1]);
      *(undefined2 *)(iVar8 + 0x34) = uVar1;
      *(undefined2 *)(iVar8 + 100) = uVar1;
      iVar7 = param_1[0x5a];
      puVar5 = (undefined4 *)FUN_00590ae0(auStack_c,iVar7 + 4);
      uVar1 = FUN_005ee080(*puVar5,puVar5[1]);
      *(undefined2 *)(iVar7 + 0x34) = uVar1;
      *(undefined2 *)(iVar7 + 100) = uVar1;
      iVar7 = param_1[0x5a];
      iVar8 = *(int *)(*(int *)(iVar7 + 0x18c) + 0x1820);
      if (1U - *(int *)(iVar7 + 0x2b8) == (*(uint *)(*(int *)(iVar7 + 0x18c) + 0x19a0) & 1)) {
        iVar8 = -iVar8;
      }
      FUN_00590aa0(iVar8 - *(int *)(iVar7 + 4),-*(int *)(iVar7 + 8),-*(int *)(iVar7 + 0xc));
      sVar2 = FUN_005ee080(iStack_18,local_14);
      *(short *)(param_1[0x5a] + 0x34) =
           *(short *)(param_1[0x5a] + 0x34) + (short)(sVar2 - *(short *)(iVar7 + 0x34)) / 2;
    }
  }
  param_1[0xb8] = -1;
  FUN_005b8a60();
  return;
}


