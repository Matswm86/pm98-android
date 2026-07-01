// FUN_005b8ce0  entry=005b8ce0  size=570 bytes

void __thiscall FUN_005b8ce0(int *param_1,char param_2)

{
  int iVar1;
  bool bVar2;
  char cVar3;
  short sVar4;
  uint uVar5;
  int iVar6;
  uint uVar7;
  int iVar8;
  int *piVar9;
  int local_44;
  int local_40;
  int local_2c;
  int local_28;
  undefined4 local_14;
  undefined4 local_10;
  
  iVar1 = param_1[0x4e];
  iVar8 = param_1[0x5a];
  iVar6 = *(int *)(iVar1 + 0x1650);
  if (((iVar6 == 0) || (*(int *)(iVar1 + 0x1664) != param_1[2])) &&
     ((iVar6 = *(int *)(iVar1 + 0x165c), iVar6 == 0 || (*(int *)(iVar6 + 0x2b8) != param_1[2])))) {
    local_44 = 0x12c0000;
    if (((iVar8 != 0) && (*(char *)(iVar8 + 0x5d) != '\0')) && (param_2 == '\0')) goto LAB_005b8e8b;
    local_28 = param_1[1];
    local_2c = *param_1;
    iVar6 = iVar8;
    if (local_28 != 0) {
      piVar9 = (int *)(local_2c + 0xc);
      local_40 = iVar8;
      do {
        local_28 = local_28 + -1;
        if (piVar9[0xac] != 0) {
          if (param_2 != '\0') {
            FUN_00590aa0(piVar9[-2] - *(int *)(iVar1 + 0x1614),piVar9[-1] - *(int *)(iVar1 + 0x1618)
                         ,*piVar9 - *(int *)(iVar1 + 0x161c));
            sVar4 = FUN_005ee080(local_14,local_10);
            uVar5 = (uint)(short)(sVar4 - *(short *)(iVar1 + 0x1644));
            uVar7 = (int)uVar5 >> 0x1f;
            if (0x3554 < (int)((uVar5 ^ uVar7) - uVar7)) goto LAB_005b8e51;
          }
          iVar6 = ftol();
          iVar8 = local_40;
          if (iVar6 < local_44) {
            local_40 = local_2c;
            iVar8 = local_2c;
            local_44 = iVar6;
          }
        }
LAB_005b8e51:
        local_2c = local_2c + 0x3bc;
        piVar9 = piVar9 + 0xef;
        iVar6 = iVar8;
      } while (local_28 != 0);
    }
  }
  iVar8 = iVar6;
  if ((param_2 != '\0') && (iVar6 == 0)) {
    return;
  }
LAB_005b8e8b:
  if (param_1[0x5a] != 0) {
    *(undefined1 *)(param_1[0x5a] + 0x5c) = 0;
  }
  iVar1 = param_1[0x5a];
  param_1[0x5a] = iVar8;
  if (iVar8 != 0) {
    *(undefined1 *)(iVar8 + 0x5c) = 1;
    iVar8 = param_1[0x5a];
    if (iVar8 != iVar1) {
      if ((*(char *)(*(int *)(iVar8 + 0x184) + 0x2ee) == '\0') ||
         (cVar3 = FUN_005943b0(), cVar3 == '\0')) {
        bVar2 = false;
      }
      else {
        bVar2 = true;
      }
      if ((bVar2) && (*(char *)(iVar8 + 0x5c) != '\0')) {
        bVar2 = true;
      }
      else {
        bVar2 = false;
      }
      if (bVar2) {
        *(undefined4 *)(param_1[0x5a] + 0x54) = 0;
        *(undefined4 *)(param_1[0x5a] + 0x58) = 0;
      }
    }
  }
  return;
}


