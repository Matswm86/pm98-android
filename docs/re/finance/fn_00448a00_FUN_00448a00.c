// FUN_00448a00  entry=00448a00  size=352 bytes

uint __fastcall FUN_00448a00(int param_1)

{
  uint uVar1;
  byte bVar2;
  uint uVar3;
  uint uVar4;
  uint uVar5;
  
  bVar2 = *(byte *)(param_1 + 0x36);
  uVar4 = (uint)*(byte *)(param_1 + 0x35);
  uVar3 = (uint)*(byte *)(param_1 + 0x34);
  if ((((bVar2 != 0xff) && (*(byte *)(param_1 + 0x37) != 0xff)) && (*(int *)(param_1 + 0x58) != 0))
     && (*(int *)(param_1 + 0x48) != 0)) {
    uVar3 = (uint)bVar2;
    uVar4 = (uint)*(byte *)(param_1 + 0x37);
  }
  if (*(int *)(param_1 + 0x5c) == 0) {
LAB_00448b44:
    if (*(byte *)(param_1 + 0x3c) <= *(byte *)(param_1 + 0x3d)) {
      return -(uint)(*(byte *)(param_1 + 0x3c) < *(byte *)(param_1 + 0x3d)) & 2;
    }
    return 1;
  }
  if ((uVar3 == 0xff) && (uVar4 == 0xff)) {
    if (*(byte *)(param_1 + 0x3d) != *(byte *)(param_1 + 0x3c)) {
      return 2 - (*(byte *)(param_1 + 0x3d) < *(byte *)(param_1 + 0x3c));
    }
    if (*(int *)(param_1 + 0x50) != 0) {
      if (*(byte *)(param_1 + 0x55) < *(byte *)(param_1 + 0x54)) {
        return 1;
      }
      if (*(byte *)(param_1 + 0x54) < *(byte *)(param_1 + 0x55)) {
        return 2;
      }
    }
  }
  else {
    if ((*(int *)(param_1 + 0x30) == 0) ||
       (((*(int *)(param_1 + 0x58) != 0 && (*(int *)(param_1 + 0x48) != 0)) && (bVar2 != 0xff)))) {
      if ((uVar3 != uVar4) ||
         (uVar5 = (uint)*(byte *)(param_1 + 0x3d),
         *(byte *)(param_1 + 0x3c) != *(byte *)(param_1 + 0x3d))) {
        uVar1 = *(byte *)(param_1 + 0x3c) + uVar3;
        uVar5 = (uint)*(byte *)(param_1 + 0x3d);
        uVar4 = uVar4 + uVar5;
        if (uVar1 != uVar4) {
          if (uVar4 < uVar1) {
            return 1;
          }
          if (uVar1 < uVar4) {
            return 2;
          }
          goto LAB_00448b44;
        }
      }
    }
    else {
      uVar3 = uVar3 + *(byte *)(param_1 + 0x3c);
      uVar5 = *(byte *)(param_1 + 0x3d) + uVar4;
    }
    if (uVar5 < uVar3) {
      return 1;
    }
    if (uVar3 < uVar5) {
      return 2;
    }
    if (*(int *)(param_1 + 0x50) != 0) {
      if (*(byte *)(param_1 + 0x55) < *(byte *)(param_1 + 0x54)) {
        return 1;
      }
      if (*(byte *)(param_1 + 0x54) < *(byte *)(param_1 + 0x55)) {
        return 2;
      }
    }
  }
  return 0;
}


