// FUN_005bec80  entry=005bec80  size=1202 bytes

void __thiscall FUN_005bec80(int param_1,char param_2)

{
  int iVar1;
  bool bVar2;
  int *piVar3;
  int iVar4;
  int iVar5;
  int local_5c;
  undefined4 local_58;
  undefined4 local_54;
  undefined4 local_50;
  int local_4c;
  undefined4 local_48;
  undefined4 local_44;
  undefined4 local_40;
  int local_3c;
  int local_38;
  int local_34;
  int local_30;
  int local_24;
  int local_20;
  undefined1 local_1c [16];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00620f08;
  local_c = ExceptionList;
  if (*(char *)(param_1 + 0x3ec) == '\0') {
    return;
  }
  if (*(int *)(param_1 + 600) == 0) {
    return;
  }
  ExceptionList = &local_c;
  FUN_005bcd40(&local_3c);
  if (((*(byte *)(param_1 + 0xac) & 2) != 0) &&
     (piVar3 = *(int **)(param_1 + 0x35c), piVar3 != (int *)0x0)) {
    if ((piVar3[1] == 0) && (*piVar3 == 0)) {
      bVar2 = false;
    }
    else {
      bVar2 = true;
    }
    if ((bVar2) && (*(char *)(param_1 + 0x3ef) == '\0')) {
      iVar1 = *(int *)(param_1 + 600);
      iVar5 = *(int *)(iVar1 + 0x40c);
      if (local_3c <= iVar5) {
        iVar5 = local_3c;
      }
      *(int *)(iVar1 + 0x40c) = iVar5;
      iVar5 = *(int *)(iVar1 + 0x410);
      if (local_38 <= *(int *)(iVar1 + 0x410)) {
        iVar5 = local_38;
      }
      *(int *)(iVar1 + 0x410) = iVar5;
      iVar5 = *(int *)(iVar1 + 0x414);
      if (*(int *)(iVar1 + 0x414) <= local_34) {
        iVar5 = local_34;
      }
      *(int *)(iVar1 + 0x414) = iVar5;
      iVar5 = *(int *)(iVar1 + 0x418);
      if (*(int *)(iVar1 + 0x418) <= local_30) {
        iVar5 = local_30;
      }
      *(int *)(iVar1 + 0x418) = iVar5;
      FUN_005d6cd0(param_1);
      local_4 = 0;
      local_5c = 0;
      local_58 = 0;
      FUN_00519f00(&local_5c,*(undefined4 *)(param_1 + 0x35c),0x100);
      local_4 = 0xffffffff;
      FUN_005d6ad0();
      if (param_2 == '\0') {
        ExceptionList = local_c;
        return;
      }
      iVar1 = *(int *)(param_1 + 600);
      iVar5 = *(int *)(iVar1 + 0x3fc);
      if (local_3c <= iVar5) {
        iVar5 = local_3c;
      }
      *(int *)(iVar1 + 0x3fc) = iVar5;
      iVar5 = *(int *)(iVar1 + 0x400);
      if (local_38 <= *(int *)(iVar1 + 0x400)) {
        iVar5 = local_38;
      }
      *(int *)(iVar1 + 0x400) = iVar5;
      iVar5 = *(int *)(iVar1 + 0x404);
      if (*(int *)(iVar1 + 0x404) <= local_34) {
        iVar5 = local_34;
      }
      *(int *)(iVar1 + 0x404) = iVar5;
      iVar5 = *(int *)(iVar1 + 0x408);
      if (*(int *)(iVar1 + 0x408) <= local_30) {
        iVar5 = local_30;
      }
      *(int *)(iVar1 + 0x408) = iVar5;
      FUN_005c14e0();
      ExceptionList = local_c;
      return;
    }
  }
  if ((param_2 == '\0') || (*(char *)(param_1 + 0x3ee) != '\0')) {
    iVar1 = *(int *)(param_1 + 600);
    iVar5 = *(int *)(iVar1 + 0x40c);
    if (local_3c <= iVar5) {
      iVar5 = local_3c;
    }
    *(int *)(iVar1 + 0x40c) = iVar5;
    iVar5 = *(int *)(iVar1 + 0x410);
    if (local_38 <= *(int *)(iVar1 + 0x410)) {
      iVar5 = local_38;
    }
    *(int *)(iVar1 + 0x410) = iVar5;
    iVar5 = *(int *)(iVar1 + 0x414);
    if (*(int *)(iVar1 + 0x414) <= local_34) {
      iVar5 = local_34;
    }
    *(int *)(iVar1 + 0x414) = iVar5;
    iVar5 = *(int *)(iVar1 + 0x418);
    if (*(int *)(iVar1 + 0x418) <= local_30) {
      iVar5 = local_30;
    }
    *(int *)(iVar1 + 0x418) = iVar5;
    FUN_005c3460(&local_3c);
    *(undefined4 *)(*(int *)(param_1 + 600) + 0x42c) = 1;
    ExceptionList = local_c;
    return;
  }
  iVar1 = *(int *)(param_1 + 600);
  piVar3 = (int *)(iVar1 + 0x3fc);
  local_4c = *piVar3;
  local_48 = *(undefined4 *)(iVar1 + 0x400);
  local_44 = *(undefined4 *)(iVar1 + 0x404);
  local_40 = *(undefined4 *)(iVar1 + 0x408);
  local_5c = *(int *)(iVar1 + 0x40c);
  local_58 = *(undefined4 *)(iVar1 + 0x410);
  local_54 = *(undefined4 *)(iVar1 + 0x414);
  local_50 = *(undefined4 *)(iVar1 + 0x418);
  iVar5 = *piVar3;
  if (*piVar3 <= local_3c) {
    iVar5 = local_3c;
  }
  iVar4 = *(int *)(iVar1 + 0x404);
  if (local_34 <= *(int *)(iVar1 + 0x404)) {
    iVar4 = local_34;
  }
  if (iVar5 < iVar4) {
    iVar5 = *(int *)(iVar1 + 0x400);
    if (*(int *)(iVar1 + 0x400) <= local_38) {
      iVar5 = local_38;
    }
    iVar4 = *(int *)(iVar1 + 0x408);
    if (local_30 <= *(int *)(iVar1 + 0x408)) {
      iVar4 = local_30;
    }
    if (iVar5 < iVar4) {
      bVar2 = true;
      goto LAB_005bee9e;
    }
  }
  bVar2 = false;
LAB_005bee9e:
  if (bVar2) {
    local_48 = 0x70000000;
    local_4c = 0x70000000;
    local_40 = 0x90000000;
    local_44 = 0x90000000;
    local_58 = 0x70000000;
    local_5c = 0x70000000;
    local_50 = 0x90000000;
    local_54 = 0x90000000;
    iVar5 = *piVar3;
    if (local_3c <= *piVar3) {
      iVar5 = local_3c;
    }
    *piVar3 = iVar5;
    iVar5 = *(int *)(iVar1 + 0x400);
    if (local_38 <= *(int *)(iVar1 + 0x400)) {
      iVar5 = local_38;
    }
    *(int *)(iVar1 + 0x400) = iVar5;
    iVar5 = *(int *)(iVar1 + 0x404);
    if (*(int *)(iVar1 + 0x404) <= local_34) {
      iVar5 = local_34;
    }
    *(int *)(iVar1 + 0x404) = iVar5;
    iVar5 = *(int *)(iVar1 + 0x408);
    if (*(int *)(iVar1 + 0x408) <= local_30) {
      iVar5 = local_30;
    }
    *(int *)(iVar1 + 0x408) = iVar5;
    iVar1 = *(int *)(param_1 + 600);
    piVar3 = (int *)(iVar1 + 0x40c);
    iVar5 = *piVar3;
    if (local_3c <= *piVar3) {
      iVar5 = local_3c;
    }
    *piVar3 = iVar5;
    iVar5 = *(int *)(iVar1 + 0x410);
    if (local_38 <= *(int *)(iVar1 + 0x410)) {
      iVar5 = local_38;
    }
    *(int *)(iVar1 + 0x410) = iVar5;
    iVar5 = *(int *)(iVar1 + 0x414);
    if (*(int *)(iVar1 + 0x414) <= local_34) {
      iVar5 = local_34;
    }
    *(int *)(iVar1 + 0x414) = iVar5;
    iVar5 = *(int *)(iVar1 + 0x418);
    if (*(int *)(iVar1 + 0x418) <= local_30) {
      iVar5 = local_30;
    }
  }
  else {
    *(int *)(iVar1 + 0x40c) = local_3c;
    *(int *)(iVar1 + 0x410) = local_38;
    *(int *)(iVar1 + 0x414) = local_34;
    *(int *)(iVar1 + 0x418) = local_30;
    iVar1 = *(int *)(param_1 + 600);
    piVar3 = (int *)(iVar1 + 0x3fc);
    *piVar3 = *(int *)(iVar1 + 0x40c);
    *(undefined4 *)(iVar1 + 0x400) = *(undefined4 *)(iVar1 + 0x410);
    *(undefined4 *)(iVar1 + 0x404) = *(undefined4 *)(iVar1 + 0x414);
    iVar5 = *(int *)(iVar1 + 0x418);
  }
  piVar3[3] = iVar5;
  iVar1 = *(int *)(param_1 + 600);
  iVar5 = *(int *)(iVar1 + 0x3fc);
  iVar4 = *(int *)(iVar1 + 0x400);
  local_24 = *(int *)(iVar1 + 0x404);
  local_20 = *(int *)(iVar1 + 0x408);
  for (iVar1 = param_1; iVar1 != 0; iVar1 = *(int *)(iVar1 + 0x40)) {
    if ((*(uint *)(iVar1 + 0xac) & 0x800) == 0) {
      piVar3 = (int *)FUN_005bcd40(local_1c);
      if ((((iVar5 < *piVar3) || (piVar3[2] < local_24)) || (iVar4 < piVar3[1])) ||
         (piVar3[3] < local_20)) {
        bVar2 = false;
      }
      else {
        bVar2 = true;
      }
      if (bVar2) break;
    }
  }
  if ((iVar1 == 0) ||
     ((FUN_005c14e0(), DAT_00674c5c != 0 && (*(char *)(DAT_00674c5c + 0x3ec) != '\0')))) {
    FUN_005c14e0();
  }
  iVar1 = *(int *)(param_1 + 600);
  *(undefined4 *)(iVar1 + 0x400) = 0x70000000;
  *(undefined4 *)(iVar1 + 0x3fc) = 0x70000000;
  *(undefined4 *)(iVar1 + 0x408) = 0x90000000;
  *(undefined4 *)(iVar1 + 0x404) = 0x90000000;
  (**(code **)(**(int **)(param_1 + 600) + 0x110))();
  iVar1 = *(int *)(param_1 + 600);
  *(int *)(iVar1 + 0x3fc) = local_4c;
  *(undefined4 *)(iVar1 + 0x400) = local_48;
  *(undefined4 *)(iVar1 + 0x404) = local_44;
  *(undefined4 *)(iVar1 + 0x408) = local_40;
  iVar1 = *(int *)(param_1 + 600);
  *(int *)(iVar1 + 0x40c) = local_5c;
  *(undefined4 *)(iVar1 + 0x410) = local_58;
  *(undefined4 *)(iVar1 + 0x414) = local_54;
  *(undefined4 *)(iVar1 + 0x418) = local_50;
  ExceptionList = local_c;
  return;
}


