// FUN_0058ede0  entry=0058ede0  size=708 bytes

/* WARNING: Removing unreachable block (ram,0x0058ee8a) */
/* WARNING: Removing unreachable block (ram,0x0058ee52) */
/* WARNING: Removing unreachable block (ram,0x0058ee42) */
/* WARNING: Removing unreachable block (ram,0x0058ee98) */

char __fastcall FUN_0058ede0(int param_1)

{
  byte bVar1;
  int iVar2;
  bool bVar3;
  char cVar4;
  int iVar5;
  int iVar6;
  uint uVar7;
  char local_35;
  int local_30;
  int local_24;
  int local_18;
  
  iVar2 = *(int *)(param_1 + 0x1d4);
  local_18 = *(int *)(iVar2 + 0x1820);
  iVar6 = -0x10000 - local_18;
  local_24 = -local_18;
  local_30 = iVar6;
  if (local_24 < iVar6) {
    local_30 = local_24;
    local_24 = iVar6;
  }
  iVar6 = local_18 + 0x10000;
  iVar5 = iVar6;
  if (iVar6 < local_18) {
    iVar5 = local_18;
    local_18 = iVar6;
  }
  if (((((local_30 < *(int *)(param_1 + 4)) && (*(int *)(param_1 + 4) < local_24)) &&
       (-0x3a8f5 < *(int *)(param_1 + 8))) &&
      ((*(int *)(param_1 + 8) < 0x3a8f5 && (-1 < *(int *)(param_1 + 0xc))))) &&
     (*(int *)(param_1 + 0xc) < 0x270a3)) {
    bVar3 = true;
  }
  else {
    bVar3 = false;
  }
  if (!bVar3) {
    if (((local_18 < *(int *)(param_1 + 4)) && (*(int *)(param_1 + 4) < iVar5)) &&
       ((-0x3a8f5 < *(int *)(param_1 + 8) &&
        (((*(int *)(param_1 + 8) < 0x3a8f5 && (-1 < *(int *)(param_1 + 0xc))) &&
         (*(int *)(param_1 + 0xc) < 0x270a3)))))) {
      bVar3 = true;
    }
    else {
      bVar3 = false;
    }
    local_35 = '\0';
    if (!bVar3) goto LAB_0058ef12;
  }
  local_35 = '\x01';
LAB_0058ef12:
  if (local_35 != '\0') {
    uVar7 = (int)*(uint *)(param_1 + 8) >> 0x1f;
    bVar3 = false;
    *(byte *)(iVar2 + 0x462) =
         (0x2ffff < (int)((*(uint *)(param_1 + 8) ^ uVar7) - uVar7) ^ *(byte *)(iVar2 + 0x462)) & 1
         ^ *(byte *)(iVar2 + 0x462);
    *(byte *)(*(int *)(param_1 + 0x1d4) + 0x462) =
         (0x21eb7 < *(int *)(param_1 + 0xc)) << 1 |
         *(byte *)(*(int *)(param_1 + 0x1d4) + 0x462) & 0xfd;
    bVar1 = *(byte *)(*(int *)(param_1 + 0x1d4) + 0x462);
    if (((bVar1 & 1) == 0) || (*(int *)(param_1 + 0xc) < 0x1e666)) {
      cVar4 = '\0';
    }
    else {
      cVar4 = '\x01';
    }
    *(byte *)(*(int *)(param_1 + 0x1d4) + 0x462) = bVar1 & 0xfb | cVar4 << 2;
    *(byte *)(*(int *)(param_1 + 0x1d4) + 0x462) =
         (*(int *)(param_1 + 0xc) < 0x6667) << 3 |
         *(byte *)(*(int *)(param_1 + 0x1d4) + 0x462) & 0xf7;
    bVar1 = *(byte *)(*(int *)(param_1 + 0x1d4) + 0x462);
    *(byte *)(*(int *)(param_1 + 0x1d4) + 0x462) = bVar1 & 0xef | ((bVar1 & 7) == 0) << 4;
    FUN_005909f0(1);
    if (0x2170a < *(int *)(param_1 + 0xc)) {
      *(undefined4 *)(param_1 + 0xc) = 0x2170a;
      if (0 < *(int *)(param_1 + 0x28)) {
        bVar3 = true;
        *(int *)(param_1 + 0x28) = -*(int *)(param_1 + 0x28);
      }
    }
    uVar7 = *(uint *)(param_1 + 8);
    if (0x37333 < (int)((uVar7 ^ (int)uVar7 >> 0x1f) - ((int)uVar7 >> 0x1f))) {
      *(uint *)(param_1 + 8) = (((-1 < (int)uVar7) - 1 & 0xfffffffe) + 1) * 0x37333;
      if (((-1 < *(int *)(param_1 + 0x24)) - 1 & 0xfffffffe) + 1 ==
          ((-1 < *(int *)(param_1 + 8)) - 1 & 0xfffffffe) + 1) {
        bVar3 = true;
        *(int *)(param_1 + 0x24) = -*(int *)(param_1 + 0x24);
      }
    }
    if ((bVar3) && (FUN_005ee1c0(0x9eb8), *(char *)(*(int *)(param_1 + 0x1d4) + 0x180a) != '\0')) {
      FUN_00590f00();
    }
  }
  return local_35;
}


