// FUN_00576cd0  entry=00576cd0  size=439 bytes

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __thiscall
FUN_00576cd0(undefined2 *param_1,undefined2 param_2,int param_3,uint param_4,uint param_5,
            int param_6)

{
  uint uVar1;
  int iVar2;
  char cVar3;
  
  FUN_00576ca0();
  *param_1 = param_2;
  uVar1 = FUN_0058df90(100);
  cVar3 = (uVar1 < 0x32) + '\x01';
  if (param_5 < 0x17) {
    cVar3 = (uVar1 < 0x32) + '\x03';
LAB_00576d0c:
    *(char *)(param_1 + 0xc) = cVar3;
  }
  else if (param_5 < 0x1a) {
    *(char *)(param_1 + 0xc) = (uVar1 < 0xc) + (uVar1 < 0x19) + cVar3;
  }
  else {
    if (0x1e < param_5) goto LAB_00576d0c;
    *(char *)(param_1 + 0xc) = (uVar1 < 0x19) + cVar3;
  }
  *(byte *)((int)param_1 + 0x19) = *(byte *)(param_1 + 0xc);
  if (param_4 < 0x55) {
    if (param_4 < 0x50) {
      if (param_4 < 0x4b) {
        if (param_4 < 0x46) goto LAB_00576d68;
      }
      else {
        *(undefined4 *)(param_1 + 8) = 1;
      }
      *(undefined1 *)(param_1 + 0xd) = 0x14;
    }
    else {
      *(undefined4 *)(param_1 + 8) = 1;
      if (param_6 == 9) {
        *(undefined4 *)(param_1 + 6) = 0x49742400;
      }
    }
  }
  else {
    *(undefined4 *)(param_1 + 8) = 1;
    *(undefined4 *)(param_1 + 10) = 1;
    if (param_6 == 9) {
      *(undefined4 *)(param_1 + 6) = 0x49f42400;
    }
  }
LAB_00576d68:
  iVar2 = 0;
  if (1 < *(byte *)(param_1 + 0xc)) {
    *(undefined1 *)(param_1 + 0xd) = 0;
  }
  if (param_4 < 0x3c) {
    uVar1 = 8;
  }
  else if (param_4 < 0x41) {
    uVar1 = 7;
  }
  else if (param_4 < 0x46) {
    uVar1 = 6;
  }
  else if (param_4 < 0x4b) {
    uVar1 = 5;
  }
  else if (param_4 < 0x50) {
    uVar1 = 4;
  }
  else if (param_4 < 0x55) {
    uVar1 = 3;
  }
  else if (param_4 < 0x5a) {
    uVar1 = 2;
  }
  else {
    uVar1 = (uint)(param_4 < 0x5f);
  }
  if (param_5 < 0x14) {
    if ((0x5e < param_4) && (param_3 == 0)) {
      iVar2 = 1;
    }
  }
  else if (param_5 < 0x17) {
    iVar2 = 1;
  }
  else if (param_5 < 0x1a) {
    iVar2 = 2;
  }
  else if (param_5 < 0x1e) {
    iVar2 = 3;
  }
  else {
    iVar2 = (0x20 < param_5) + 4;
  }
  iVar2 = (iVar2 + (uVar1 + param_3 * 9) * 6) * 2;
  *(float *)(param_1 + 2) = (float)*(ushort *)(&DAT_00638788 + iVar2) * (float)_DAT_00638d08;
  *(float *)(param_1 + 4) = (float)*(ushort *)(&DAT_00638208 + iVar2) * (float)_DAT_00638d08;
  return;
}


