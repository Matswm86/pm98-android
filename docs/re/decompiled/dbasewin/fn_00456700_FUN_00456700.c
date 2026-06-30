// FUN_00456700  entry=00456700  size=1202 bytes

void __thiscall FUN_00456700(void *this,char param_1)

{
  int iVar1;
  bool bVar2;
  int *piVar3;
  int *piVar4;
  int iVar5;
  int iVar6;
  int local_5c;
  undefined4 local_58;
  undefined4 local_54;
  undefined4 local_50;
  int local_4c;
  undefined4 local_48;
  void *local_44;
  undefined4 local_40;
  int local_3c;
  int local_38;
  int local_34;
  int local_30;
  int local_24;
  int local_20;
  int local_1c [4];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00482b48;
  local_c = ExceptionList;
  if (*(char *)((int)this + 0x3ec) == '\0') {
    return;
  }
  if (*(int *)((int)this + 600) == 0) {
    return;
  }
  ExceptionList = &local_c;
  FUN_004547c0(this,&local_3c);
  if (((*(byte *)((int)this + 0xac) & 2) != 0) &&
     (piVar3 = *(int **)((int)this + 0x35c), piVar3 != (int *)0x0)) {
    if ((piVar3[1] == 0) && (*piVar3 == 0)) {
      bVar2 = false;
    }
    else {
      bVar2 = true;
    }
    if ((bVar2) && (*(char *)((int)this + 0x3ef) == '\0')) {
      iVar1 = *(int *)((int)this + 600);
      iVar6 = *(int *)(iVar1 + 0x40c);
      if (local_3c <= iVar6) {
        iVar6 = local_3c;
      }
      *(int *)(iVar1 + 0x40c) = iVar6;
      iVar6 = *(int *)(iVar1 + 0x410);
      if (local_38 <= *(int *)(iVar1 + 0x410)) {
        iVar6 = local_38;
      }
      *(int *)(iVar1 + 0x410) = iVar6;
      iVar6 = *(int *)(iVar1 + 0x414);
      if (*(int *)(iVar1 + 0x414) <= local_34) {
        iVar6 = local_34;
      }
      *(int *)(iVar1 + 0x414) = iVar6;
      iVar6 = *(int *)(iVar1 + 0x418);
      if (*(int *)(iVar1 + 0x418) <= local_30) {
        iVar6 = local_30;
      }
      *(int *)(iVar1 + 0x418) = iVar6;
      FUN_00451670(&local_4c,this);
      local_4 = 0;
      local_5c = 0;
      local_58 = 0;
      FUN_00415770(local_44,&local_5c,*(int **)((int)this + 0x35c),0x100);
      local_4 = 0xffffffff;
      FUN_00451470(&local_4c);
      if (param_1 == '\0') {
        ExceptionList = local_c;
        return;
      }
      iVar1 = *(int *)((int)this + 600);
      iVar6 = *(int *)(iVar1 + 0x3fc);
      if (local_3c <= iVar6) {
        iVar6 = local_3c;
      }
      *(int *)(iVar1 + 0x3fc) = iVar6;
      iVar6 = *(int *)(iVar1 + 0x400);
      if (local_38 <= *(int *)(iVar1 + 0x400)) {
        iVar6 = local_38;
      }
      *(int *)(iVar1 + 0x400) = iVar6;
      iVar6 = *(int *)(iVar1 + 0x404);
      if (*(int *)(iVar1 + 0x404) <= local_34) {
        iVar6 = local_34;
      }
      *(int *)(iVar1 + 0x404) = iVar6;
      iVar6 = *(int *)(iVar1 + 0x408);
      if (*(int *)(iVar1 + 0x408) <= local_30) {
        iVar6 = local_30;
      }
      *(int *)(iVar1 + 0x408) = iVar6;
      FUN_00458f00(this);
      ExceptionList = local_c;
      return;
    }
  }
  if ((param_1 == '\0') || (*(char *)((int)this + 0x3ee) != '\0')) {
    iVar1 = *(int *)((int)this + 600);
    iVar6 = *(int *)(iVar1 + 0x40c);
    if (local_3c <= iVar6) {
      iVar6 = local_3c;
    }
    *(int *)(iVar1 + 0x40c) = iVar6;
    iVar6 = *(int *)(iVar1 + 0x410);
    if (local_38 <= *(int *)(iVar1 + 0x410)) {
      iVar6 = local_38;
    }
    *(int *)(iVar1 + 0x410) = iVar6;
    iVar6 = *(int *)(iVar1 + 0x414);
    if (*(int *)(iVar1 + 0x414) <= local_34) {
      iVar6 = local_34;
    }
    *(int *)(iVar1 + 0x414) = iVar6;
    iVar6 = *(int *)(iVar1 + 0x418);
    if (*(int *)(iVar1 + 0x418) <= local_30) {
      iVar6 = local_30;
    }
    *(int *)(iVar1 + 0x418) = iVar6;
    FUN_0045ae20((void *)(*(int *)((int)this + 600) + 0x3fc),&local_3c);
    *(undefined4 *)(*(int *)((int)this + 600) + 0x42c) = 1;
    ExceptionList = local_c;
    return;
  }
  iVar1 = *(int *)((int)this + 600);
  piVar3 = (int *)(iVar1 + 0x3fc);
  local_4c = *piVar3;
  local_48 = *(undefined4 *)(iVar1 + 0x400);
  local_44 = *(void **)(iVar1 + 0x404);
  local_40 = *(undefined4 *)(iVar1 + 0x408);
  local_5c = *(int *)(iVar1 + 0x40c);
  local_58 = *(undefined4 *)(iVar1 + 0x410);
  local_54 = *(undefined4 *)(iVar1 + 0x414);
  local_50 = *(undefined4 *)(iVar1 + 0x418);
  iVar6 = *piVar3;
  if (*piVar3 <= local_3c) {
    iVar6 = local_3c;
  }
  iVar5 = *(int *)(iVar1 + 0x404);
  if (local_34 <= *(int *)(iVar1 + 0x404)) {
    iVar5 = local_34;
  }
  if (iVar6 < iVar5) {
    iVar6 = *(int *)(iVar1 + 0x400);
    if (*(int *)(iVar1 + 0x400) <= local_38) {
      iVar6 = local_38;
    }
    iVar5 = *(int *)(iVar1 + 0x408);
    if (local_30 <= *(int *)(iVar1 + 0x408)) {
      iVar5 = local_30;
    }
    if (iVar5 <= iVar6) goto LAB_0045691c;
    bVar2 = true;
  }
  else {
LAB_0045691c:
    bVar2 = false;
  }
  if (bVar2) {
    local_48 = 0x70000000;
    local_4c = 0x70000000;
    local_40 = 0x90000000;
    local_44 = (void *)0x90000000;
    local_58 = 0x70000000;
    local_5c = 0x70000000;
    local_50 = 0x90000000;
    local_54 = 0x90000000;
    iVar6 = *piVar3;
    if (local_3c <= *piVar3) {
      iVar6 = local_3c;
    }
    *piVar3 = iVar6;
    iVar6 = *(int *)(iVar1 + 0x400);
    if (local_38 <= *(int *)(iVar1 + 0x400)) {
      iVar6 = local_38;
    }
    *(int *)(iVar1 + 0x400) = iVar6;
    iVar6 = *(int *)(iVar1 + 0x404);
    if (*(int *)(iVar1 + 0x404) <= local_34) {
      iVar6 = local_34;
    }
    *(int *)(iVar1 + 0x404) = iVar6;
    iVar6 = *(int *)(iVar1 + 0x408);
    if (*(int *)(iVar1 + 0x408) <= local_30) {
      iVar6 = local_30;
    }
    *(int *)(iVar1 + 0x408) = iVar6;
    iVar1 = *(int *)((int)this + 600);
    piVar3 = (int *)(iVar1 + 0x40c);
    iVar6 = *piVar3;
    if (local_3c <= *piVar3) {
      iVar6 = local_3c;
    }
    *piVar3 = iVar6;
    iVar6 = *(int *)(iVar1 + 0x410);
    if (local_38 <= *(int *)(iVar1 + 0x410)) {
      iVar6 = local_38;
    }
    *(int *)(iVar1 + 0x410) = iVar6;
    iVar6 = *(int *)(iVar1 + 0x414);
    if (*(int *)(iVar1 + 0x414) <= local_34) {
      iVar6 = local_34;
    }
    *(int *)(iVar1 + 0x414) = iVar6;
    iVar6 = *(int *)(iVar1 + 0x418);
    if (*(int *)(iVar1 + 0x418) <= local_30) {
      iVar6 = local_30;
    }
  }
  else {
    *(int *)(iVar1 + 0x40c) = local_3c;
    *(int *)(iVar1 + 0x410) = local_38;
    *(int *)(iVar1 + 0x414) = local_34;
    *(int *)(iVar1 + 0x418) = local_30;
    iVar1 = *(int *)((int)this + 600);
    piVar3 = (int *)(iVar1 + 0x3fc);
    *piVar3 = *(int *)(iVar1 + 0x40c);
    *(undefined4 *)(iVar1 + 0x400) = *(undefined4 *)(iVar1 + 0x410);
    *(undefined4 *)(iVar1 + 0x404) = *(undefined4 *)(iVar1 + 0x414);
    iVar6 = *(int *)(iVar1 + 0x418);
  }
  piVar3[3] = iVar6;
  iVar1 = *(int *)((int)this + 600);
  iVar6 = *(int *)(iVar1 + 0x3fc);
  iVar5 = *(int *)(iVar1 + 0x400);
  local_24 = *(int *)(iVar1 + 0x404);
  local_20 = *(int *)(iVar1 + 0x408);
  for (piVar3 = this; piVar3 != (int *)0x0; piVar3 = (int *)piVar3[0x10]) {
    if ((piVar3[0x2b] & 0x800U) == 0) {
      piVar4 = (int *)FUN_004547c0(piVar3,local_1c);
      if ((((iVar6 < *piVar4) || (piVar4[2] < local_24)) || (iVar5 < piVar4[1])) ||
         (piVar4[3] < local_20)) {
        bVar2 = false;
      }
      else {
        bVar2 = true;
      }
      if (bVar2) break;
    }
  }
  if (piVar3 == (int *)0x0) {
    piVar3 = *(int **)((int)this + 600);
  }
  else {
    FUN_00458f00(piVar3);
    if ((DAT_00501da4 == (int *)0x0) || (piVar3 = DAT_00501da4, (char)DAT_00501da4[0xfb] == '\0'))
    goto LAB_00456aaa;
  }
  FUN_00458f00(piVar3);
LAB_00456aaa:
  iVar1 = *(int *)((int)this + 600);
  *(undefined4 *)(iVar1 + 0x400) = 0x70000000;
  *(undefined4 *)(iVar1 + 0x3fc) = 0x70000000;
  *(undefined4 *)(iVar1 + 0x408) = 0x90000000;
  *(undefined4 *)(iVar1 + 0x404) = 0x90000000;
  (**(code **)(**(int **)((int)this + 600) + 0x110))();
  iVar1 = *(int *)((int)this + 600);
  *(int *)(iVar1 + 0x3fc) = local_4c;
  *(undefined4 *)(iVar1 + 0x400) = local_48;
  *(void **)(iVar1 + 0x404) = local_44;
  *(undefined4 *)(iVar1 + 0x408) = local_40;
  iVar1 = *(int *)((int)this + 600);
  *(int *)(iVar1 + 0x40c) = local_5c;
  *(undefined4 *)(iVar1 + 0x410) = local_58;
  *(undefined4 *)(iVar1 + 0x414) = local_54;
  *(undefined4 *)(iVar1 + 0x418) = local_50;
  ExceptionList = local_c;
  return;
}


