// FUN_005e5100  entry=005e5100  size=374 bytes

undefined4 * __thiscall
FUN_005e5100(undefined4 *param_1,undefined4 param_2,undefined4 param_3,uint param_4,uint param_5,
            int param_6)

{
  int iVar1;
  uint uVar2;
  undefined4 *puVar3;
  
  puVar3 = param_1;
  for (iVar1 = 0x1b; iVar1 != 0; iVar1 = iVar1 + -1) {
    *puVar3 = 0;
    puVar3 = puVar3 + 1;
  }
  param_1[3] = param_2;
  *param_1 = 0x6c;
  param_1[0x12] = 0x20;
  param_1[2] = param_3;
  if ((param_5 & 4) == 0) {
    uVar2 = (-(uint)((param_5 & 8) != 0) & 0x1dfc0) + 0x2040;
  }
  else {
    uVar2 = 0x1000;
  }
  param_1[0x1a] = (~param_5 & 1) << 0xb | uVar2;
  param_1[0x11] = param_6;
  uVar2 = (param_4 != 8) - 1 & 0x20;
  param_1[0x10] = param_6;
  param_1[0x13] = uVar2 | 0x40;
  param_1[6] = param_4 & 0xfffffff8;
  param_1[0x15] = param_4 & 0xfffffff8;
  switch(param_4) {
  case 0x10:
    param_1[0x16] = 0xf800;
    param_1[0x17] = 0x7e0;
    param_1[0x18] = 0x1f;
    break;
  case 0x11:
    param_1[0x16] = 0x7c00;
    param_1[0x17] = 0x3e0;
    param_1[0x18] = 0x1f;
    break;
  case 0x12:
    param_1[0x16] = 0x7c00;
    param_1[0x17] = 0x3e0;
    param_1[0x18] = 0x1f;
    param_1[0x19] = 0x8000;
    goto LAB_005e5246;
  case 0x13:
    param_1[0x16] = 0xf00;
    param_1[0x17] = 0xf0;
    param_1[0x18] = 0xf;
    param_1[0x19] = 0xf000;
    goto LAB_005e5246;
  case 0x18:
    param_1[0x16] = 0xff0000;
    param_1[0x17] = 0xff00;
    param_1[0x18] = 0xff;
    break;
  case 0x20:
    param_1[0x16] = 0xff0000;
    param_1[0x17] = 0xff00;
    param_1[0x18] = 0xff;
    param_1[0x19] = 0xff000000;
LAB_005e5246:
    param_1[0x13] = uVar2 | 0x41;
  }
  iVar1 = (-(uint)((param_5 & 8) != 0) & 0xfffff040) + 0x1000;
  param_1[1] = CONCAT31((uint3)((uint)iVar1 >> 8) | (uint3)(-(uint)(param_6 != -1) >> 8) & 0x100,
                        (char)iVar1) | 7;
  return param_1;
}


