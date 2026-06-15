// FUN_005983f0  entry=005983f0  size=667 bytes
// callers/callees expanded one level from seeds

undefined4 __fastcall FUN_005983f0(int param_1)

{
  char cVar1;
  byte bVar2;
  undefined4 *puVar3;
  undefined4 uVar4;
  undefined3 uVar5;
  undefined3 extraout_var;
  undefined3 extraout_var_00;
  undefined4 *puVar6;
  int iVar7;
  bool bVar8;
  
  iVar7 = 2;
  *(undefined1 *)(param_1 + 0x1a19) = 0;
  do {
    FUN_005b6ee0();
    iVar7 = iVar7 + -1;
  } while (iVar7 != 0);
  cVar1 = FUN_005943d0();
  if (cVar1 == '\0') {
    cVar1 = FUN_005943b0();
    if (cVar1 != '\0') goto LAB_00598432;
    bVar8 = false;
  }
  else {
LAB_00598432:
    bVar8 = true;
  }
  if (((bVar8) || (*(int *)(param_1 + 0x19a0) == 4)) || (*(char *)(param_1 + 0x1a20) != '\0')) {
    cVar1 = FUN_005943f0();
    if ((cVar1 == '\0') || (*(int *)(param_1 + 0x19a0) == 4)) {
      bVar8 = false;
    }
    else {
      bVar8 = true;
    }
    FUN_00451200();
    FUN_00594310();
    while( true ) {
      FUN_00593ab0();
      if ((*(char *)(param_1 + 0x1a19) != '\0') || (bVar8)) break;
      if ((((*(int *)(param_1 + 0x1a2c) != 0) &&
           ((iVar7 = *(int *)(param_1 + 0x1a38), iVar7 != 3 && (iVar7 != 4)))) &&
          ((iVar7 != 5 || ((*(byte *)(param_1 + 0x461) & 6) != 0)))) ||
         ((*(int *)(param_1 + 0x1a38) == 10 || (*(char *)(param_1 + 0x1a1f) != '\0')))) break;
    }
    puVar3 = (undefined4 *)(param_1 + 0x19b0);
    puVar6 = (undefined4 *)(param_1 + 0x478);
    iVar7 = 2;
    do {
      uVar4 = *puVar6;
      puVar6 = puVar6 + 200;
      *puVar3 = uVar4;
      puVar3 = puVar3 + 1;
      iVar7 = iVar7 + -1;
    } while (iVar7 != 0);
    FUN_00594570(1);
    FUN_00594380();
    uVar4 = FUN_004511f0();
    uVar5 = (undefined3)((uint)uVar4 >> 8);
    if (((*(char *)(param_1 + 0x1a1e) == '\0') && (*(int *)(param_1 + 0x1a38) != 10)) &&
       (*(char *)(param_1 + 0x1a19) == '\0')) {
      bVar8 = true;
    }
    else {
      bVar8 = false;
    }
  }
  else {
    *(undefined1 *)(param_1 + 0x180e) = 0;
    cVar1 = FUN_00598740();
    if (cVar1 == '\0') {
      *(undefined1 *)(param_1 + 0x1a1e) = 1;
    }
    if (((*(int *)(param_1 + 0x440) == 0) ||
        (*(char *)(*(int *)(*(int *)(param_1 + 0x440) + 0x184) + 0x2ee) == '\0')) &&
       (DAT_00674cb3 == '\0')) {
      bVar2 = 0;
    }
    else {
      bVar2 = 1;
    }
    *(byte *)(param_1 + 0x1a1f) = *(byte *)(param_1 + 0x1a1f) | bVar2;
    bVar8 = *(int *)(param_1 + 0x1a38) != 10;
    puVar3 = (undefined4 *)FUN_005943f0();
    if ((char)puVar3 == '\0') {
LAB_005984f1:
      uVar5 = (undefined3)((uint)puVar3 >> 8);
      puVar3 = (undefined4 *)CONCAT31(uVar5,*(char *)(param_1 + 0x1a1e));
      if ((*(char *)(param_1 + 0x1a1e) != '\0') &&
         (puVar3 = (undefined4 *)CONCAT31(uVar5,*(char *)(param_1 + 0x1a1f)),
         *(char *)(param_1 + 0x1a1f) != '\0')) goto LAB_00598505;
    }
    else {
      uVar4 = FUN_00598340();
      if ((char)uVar4 == '\0') {
        puVar3 = (undefined4 *)CONCAT31((int3)((uint)uVar4 >> 8),*(char *)(param_1 + 0x1a1e));
        if (*(char *)(param_1 + 0x1a1e) == '\0') goto LAB_0059855c;
        if (*(int *)(param_1 + 0x1a2c) != 2) goto LAB_005984f1;
      }
LAB_00598505:
      cVar1 = FUN_005943f0();
      if ((cVar1 != '\0') &&
         ((*(int *)(param_1 + 0x1a38) == 6 ||
          (((*(int *)(param_1 + 0x1a38) == 3 && (*(char *)(param_1 + 0x1a1f) == '\0')) ||
           (*(int *)(param_1 + 0x1a2c) == 1)))))) {
        FUN_00598690();
      }
      puVar3 = (undefined4 *)(param_1 + 0x19b0);
      puVar6 = (undefined4 *)(param_1 + 0x478);
      iVar7 = 2;
      do {
        uVar4 = *puVar6;
        puVar6 = puVar6 + 200;
        *puVar3 = uVar4;
        puVar3 = puVar3 + 1;
        iVar7 = iVar7 + -1;
      } while (iVar7 != 0);
      bVar8 = false;
    }
LAB_0059855c:
    if ((bVar8 != false) &&
       (uVar5 = (undefined3)((uint)puVar3 >> 8), *(char *)(param_1 + 0x1a1e) == '\0'))
    goto LAB_00598684;
    FUN_00594570(1);
    uVar5 = extraout_var;
  }
  if (*(char *)(param_1 + 0x1a1e) != '\0') {
    FUN_0044d3d0(0);
    FUN_0044d3d0(1);
    uVar5 = extraout_var_00;
  }
LAB_00598684:
  return CONCAT31(uVar5,bVar8);
}


